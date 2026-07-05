#!/usr/bin/env node
// Interactive front-end for tools/setup.sh.
// Prompts on stderr, prints the resulting setup.sh argv (one arg per line)
// on stdout. setup.sh re-invokes itself with that argv, so all validation
// and install logic stays in setup.sh.
import { existsSync, mkdirSync, readdirSync, statSync } from 'node:fs';
import { createRequire } from 'node:module';
import { execFileSync } from 'node:child_process';
import { homedir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import * as readline from 'node:readline/promises';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');
const note = (text) => process.stderr.write(text);

// --- prompt backends -------------------------------------------------------

async function loadInquirer() {
  if (process.env.AI_DOTFILES_WIZARD_UI === 'basic') return null;
  try {
    return await import('@inquirer/prompts');
  } catch {
    // not installed locally; fall through to cached copy
  }

  const cacheDir = join(homedir(), '.cache', 'ai-dotfiles', 'wizard');
  const installed = join(cacheDir, 'node_modules', '@inquirer', 'prompts');
  if (!existsSync(installed)) {
    note('Fetching @inquirer/prompts for arrow-key menus (one-time, cached)...\n');
    try {
      mkdirSync(cacheDir, { recursive: true });
      execFileSync(
        'npm',
        [
          'install', '--prefix', cacheDir,
          '--no-audit', '--no-fund', '--loglevel=error',
          '--fetch-retries=1', '--fetch-retry-mintimeout=2000', '--fetch-retry-maxtimeout=5000',
          '@inquirer/prompts',
        ],
        { stdio: ['ignore', 'ignore', 'inherit'] },
      );
    } catch {
      note('Could not fetch @inquirer/prompts (offline?); using numbered prompts instead.\n');
      return null;
    }
  }
  try {
    const req = createRequire(join(cacheDir, 'noop.js'));
    return await import(pathToFileURL(req.resolve('@inquirer/prompts')).href);
  } catch {
    note('Cached @inquirer/prompts unusable; using numbered prompts instead.\n');
    return null;
  }
}

function makeUi(inq) {
  if (inq) {
    const ctx = { output: process.stderr };
    return {
      select: (opts) => inq.select(opts, ctx),
      checkbox: (opts) => inq.checkbox(opts, ctx),
      input: (opts) => inq.input(opts, ctx),
      confirm: (opts) => inq.confirm(opts, ctx),
      close: () => {},
    };
  }

  const rl = readline.createInterface({ input: process.stdin, output: process.stderr });

  // rl.question drops lines that arrive while no question is pending (e.g.
  // piped input), so buffer every line ourselves and hand them out in order.
  const pending = [];
  const waiters = [];
  let stdinClosed = false;
  rl.on('line', (line) => {
    const waiter = waiters.shift();
    if (waiter) waiter(line);
    else pending.push(line);
  });
  rl.on('close', () => {
    stdinClosed = true;
    while (waiters.length) waiters.shift()(null);
  });

  const question = async (prompt) => {
    note(prompt);
    if (pending.length) return pending.shift();
    if (stdinClosed) return null;
    return new Promise((resolveLine) => waiters.push(resolveLine));
  };

  const answerOrAbort = async (prompt) => {
    const line = await question(prompt);
    if (line === null) {
      const abort = new Error('stdin closed');
      abort.name = 'ExitPromptError';
      throw abort;
    }
    return line.trim();
  };

  const printChoices = (message, choices) => {
    note(`\n${message}\n`);
    choices.forEach((choice, i) => {
      const desc = choice.description ? `  - ${choice.description}` : '';
      note(`  ${i + 1}) ${choice.name}${desc}\n`);
    });
  };

  return {
    async select({ message, choices, default: def }) {
      printChoices(message, choices);
      const defIndex = Math.max(0, choices.findIndex((c) => c.value === def));
      for (;;) {
        const raw = await answerOrAbort(`Choose 1-${choices.length} [${defIndex + 1}]: `);
        if (raw === '') return choices[defIndex].value;
        const idx = Number(raw) - 1;
        if (Number.isInteger(idx) && idx >= 0 && idx < choices.length) return choices[idx].value;
        note('Invalid choice, try again.\n');
      }
    },
    async checkbox({ message, choices }) {
      printChoices(`${message} (comma-separated numbers, empty for none)`, choices);
      for (;;) {
        const raw = await answerOrAbort('Choose: ');
        if (raw === '') return [];
        const idxs = raw.split(',').map((s) => Number(s.trim()) - 1);
        if (idxs.every((i) => Number.isInteger(i) && i >= 0 && i < choices.length)) {
          return [...new Set(idxs)].map((i) => choices[i].value);
        }
        note('Invalid choice, try again.\n');
      }
    },
    async input({ message, default: def = '', validate }) {
      for (;;) {
        const raw = await answerOrAbort(`${message}${def ? ` [${def}]` : ''}: `);
        const value = raw === '' ? def : raw;
        const verdict = validate ? validate(value) : true;
        if (verdict === true) return value;
        note(`${verdict}\n`);
      }
    },
    async confirm({ message, default: def = true }) {
      const hint = def ? 'Y/n' : 'y/N';
      for (;;) {
        const raw = (await answerOrAbort(`${message} (${hint}): `)).toLowerCase();
        if (raw === '') return def;
        if (['y', 'yes'].includes(raw)) return true;
        if (['n', 'no'].includes(raw)) return false;
        note('Answer y or n.\n');
      }
    },
    close: () => rl.close(),
  };
}

// --- discovery --------------------------------------------------------------

function discoverProfiles() {
  const names = new Set();
  const scan = (base) => {
    const dir = join(base, 'profiles');
    if (!existsSync(dir)) return;
    for (const entry of readdirSync(dir, { withFileTypes: true })) {
      if (entry.isDirectory()) names.add(entry.name);
    }
  };
  scan(ROOT);
  if (process.env.AI_DOTFILES_PROFILES) scan(process.env.AI_DOTFILES_PROFILES);
  return [...names].sort();
}

function discoverPlugins() {
  const dir = join(ROOT, 'shared', 'plugins');
  if (!existsSync(dir)) return [];
  return readdirSync(dir, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .sort();
}

function validateRepoPath(value) {
  if (value === '') return true;
  const expanded = value.startsWith('~') ? join(homedir(), value.slice(1)) : value;
  const abs = resolve(expanded);
  if (abs === homedir()) return 'Refusing to scaffold into your home directory; pick a project directory.';
  if (abs === '/') return 'Refusing to scaffold into the filesystem root.';
  if (existsSync(abs) && !statSync(abs).isDirectory()) return `Not a directory: ${abs}`;
  return true;
}

// --- question flow -----------------------------------------------------------

async function askAll(ui, prev) {
  const answers = {};

  answers.editor = await ui.select({
    message: 'Which editor(s) should be configured?',
    choices: [
      { name: 'vscode', value: 'vscode', description: 'VS Code / GitHub Copilot config only' },
      { name: 'cursor', value: 'cursor', description: 'Cursor config only (rules, skills, hooks, MCP)' },
      { name: 'both', value: 'both', description: 'Install both VS Code and Cursor baselines' },
    ],
    default: prev.editor ?? 'vscode',
  });
  const vscode = answers.editor === 'vscode' || answers.editor === 'both';
  const cursor = answers.editor === 'cursor' || answers.editor === 'both';

  const profiles = discoverProfiles();
  answers.profile = await ui.select({
    message: 'Profile to apply? (bundles rules/commands/agents for a specific project; "none" installs only the generic baseline)',
    choices: [
      { name: 'none', value: '', description: 'No project profile, generic baseline only' },
      ...profiles.map((name) => ({ name, value: name, description: `profiles/${name}/` })),
    ],
    default: prev.profile ?? '',
  });

  answers.repo = await ui.input({
    message: 'Target repository to scaffold with project config (empty to skip)',
    default: prev.repo ?? '',
    validate: validateRepoPath,
  });

  answers.plugins = [];
  if (cursor) {
    const plugins = discoverPlugins();
    if (plugins.length > 0) {
      answers.plugins = await ui.checkbox({
        message: 'Optional Cursor plugins to install?',
        choices: plugins.map((name) => ({
          name,
          value: name,
          description: `shared/plugins/${name}/`,
          checked: (prev.plugins ?? []).includes(name),
        })),
      });
    }
  }

  answers.installExtensions = false;
  answers.workspaceMode = 'direct';
  answers.userMcpMode = 'direct';
  if (vscode) {
    answers.installExtensions = await ui.confirm({
      message: 'Install VS Code extensions from shared/extensions.txt?',
      default: prev.installExtensions ?? false,
    });
    answers.userMcpMode = await ui.select({
      message: 'User-level MCP mode? (how user MCP servers are launched in VS Code)',
      choices: [
        { name: 'direct', value: 'direct', description: 'Editor starts MCP servers directly (default)' },
        { name: 'autostart', value: 'autostart', description: 'Servers launched by autostart helper script' },
      ],
      default: prev.userMcpMode ?? 'direct',
    });
    if (answers.repo) {
      answers.workspaceMode = await ui.select({
        message: 'Workspace MCP mode for the scaffolded repo?',
        choices: [
          { name: 'direct', value: 'direct', description: 'Workspace MCP config launched by editor (default)' },
          { name: 'autostart', value: 'autostart', description: 'Workspace autostart templates + dry-run' },
        ],
        default: prev.workspaceMode ?? 'direct',
      });
    }
  }

  answers.userBaseline = await ui.confirm({
    message: 'Install user-level baseline (instructions, rules, skills, MCP templates)?',
    default: prev.userBaseline ?? true,
  });

  return answers;
}

// --- argv + summary ----------------------------------------------------------

function buildArgs(a) {
  const args = ['--editor', a.editor];
  if (a.profile) args.push('--profile', a.profile);
  if (a.repo) args.push('--repo', a.repo);
  for (const plugin of a.plugins) args.push('--plugin', plugin);
  if (a.installExtensions) args.push('--install-extensions');
  if (a.workspaceMode !== 'direct') args.push('--workspace-mode', a.workspaceMode);
  if (a.userMcpMode !== 'direct') args.push('--user-mcp-mode', a.userMcpMode);
  if (!a.userBaseline) args.push('--skip-user-baseline');
  return args;
}

const shQuote = (s) => (/^[A-Za-z0-9_@%+=:,./-]+$/.test(s) ? s : `'${s.replaceAll("'", "'\\''")}'`);

function printSummary(a, args) {
  const rows = [
    ['Editor', a.editor],
    ['Profile', a.profile || '(none)'],
    ['Repo scaffold', a.repo || '(skipped)'],
    ['Plugins', a.plugins.length ? a.plugins.join(', ') : '(none)'],
    ['VS Code extensions', a.installExtensions ? 'yes' : 'no'],
    ['User MCP mode', a.userMcpMode],
    ['Workspace MCP mode', a.workspaceMode],
    ['User baseline', a.userBaseline ? 'yes' : 'no'],
  ];
  note('\nSummary:\n');
  for (const [label, value] of rows) note(`  ${label.padEnd(20)} ${value}\n`);
  note('\nEquivalent non-interactive command (reusable in CI/scripts):\n');
  note(`  tools/setup.sh ${args.map(shQuote).join(' ')}\n\n`);
}

// --- main ---------------------------------------------------------------------

async function main() {
  note('ai-dotfiles interactive setup - answers only build a setup.sh command; nothing is installed until you confirm.\n');

  const ui = makeUi(await loadInquirer());
  let answers = {};

  for (;;) {
    answers = await askAll(ui, answers);
    const args = buildArgs(answers);
    printSummary(answers, args);

    const action = await ui.select({
      message: 'Proceed?',
      choices: [
        { name: 'Run setup with these options', value: 'run' },
        { name: 'Change answers (re-run questions, current values as defaults)', value: 'edit' },
        { name: 'Abort (nothing installed)', value: 'abort' },
      ],
      default: 'run',
    });

    if (action === 'run') {
      ui.close();
      process.stdout.write(buildArgs(answers).join('\n') + '\n');
      return 0;
    }
    if (action === 'abort') {
      ui.close();
      note('Aborted.\n');
      return 1;
    }
  }
}

main()
  .then((code) => process.exit(code))
  .catch((error) => {
    // Ctrl+C inside inquirer throws ExitPromptError; treat as abort.
    if (error?.name !== 'ExitPromptError') {
      process.stderr.write(`wizard error: ${error?.message ?? error}\n`);
    }
    process.exit(1);
  });
