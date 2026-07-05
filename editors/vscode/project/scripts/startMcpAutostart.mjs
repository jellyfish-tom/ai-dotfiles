import { spawn } from "node:child_process";
import { existsSync, openSync } from "node:fs";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import http from "node:http";
import os from "node:os";
import path from "node:path";

const workspaceRoot = process.cwd();
const userConfigDir = path.join(
  os.homedir(),
  "Library",
  "Application Support",
  "Code",
  "User",
);
const logDir = path.join(workspaceRoot, "tmp", "mcp-autostart");
const isDryRun = process.argv.includes("--dry-run");
const isStatusOnly = process.argv.includes("--status");

const PORTS = {
  "user:Playwright": 37101,
  "user:Jira-Server-MCP": 37102,
  "user:agentmemory": 37103,
  "user:console-ninja": 37104,
  "workspace:codegraph": 37201,
};

const sourceConfigs = [
  {
    scope: "workspace",
    filePath: path.join(workspaceRoot, ".vscode", "mcp.autostart.sources.json"),
    targetFilePath: path.join(workspaceRoot, ".vscode", "mcp.json"),
    cwd: workspaceRoot,
    workspaceFolder: workspaceRoot,
  },
  {
    scope: "user",
    filePath: path.join(userConfigDir, "mcp.autostart.sources.json"),
    targetFilePath: path.join(userConfigDir, "mcp.json"),
    cwd: userConfigDir,
    workspaceFolder: workspaceRoot,
  },
];

const sanitizeFileName = (value) =>
  value.toLowerCase().replace(/[^a-z0-9]+/g, "-");

const normalizeInputId = (value) =>
  value
    .replace(/[^a-zA-Z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "")
    .toUpperCase();

const shellQuote = (value) => `'${value.replace(/'/g, `'\\''`)}'`;

const getBridgeUrl = (port) => `http://127.0.0.1:${port}/mcp`;

const serializeConfig = (config) => `${JSON.stringify(config, null, 2)}\n`;

const stableStringify = (value) => {
  if (Array.isArray(value)) {
    return `[${value.map((item) => stableStringify(item)).join(",")}]`;
  }

  if (value && typeof value === "object") {
    const entries = Object.entries(value).sort(([left], [right]) =>
      left.localeCompare(right),
    );

    return `{${entries
      .map(
        ([key, nestedValue]) =>
          `${JSON.stringify(key)}:${stableStringify(nestedValue)}`,
      )
      .join(",")}}`;
  }

  return JSON.stringify(value);
};

const resolveTemplate = (value, workspaceFolder, envKey) => {
  const unresolved = [];

  const resolved = value
    .replace(/\$\{workspaceFolder\}/g, workspaceFolder)
    .replace(/\$\{env:([^}]+)\}/g, (_match, name) => {
      const envValue = process.env[name];

      if (envValue === undefined) {
        unresolved.push(`env:${name}`);
        return "";
      }

      return envValue;
    })
    .replace(/\$\{input:([^}]+)\}/g, (_match, inputId) => {
      const normalizedInput = `MCP_INPUT_${normalizeInputId(inputId)}`;
      const inputValue =
        (envKey ? process.env[envKey] : undefined) ??
        process.env[normalizedInput];

      if (inputValue === undefined) {
        unresolved.push(`input:${inputId}`);
        return "";
      }

      return inputValue;
    });

  return { resolved, unresolved };
};

const readConfig = async (filePath) => {
  if (!existsSync(filePath)) {
    return null;
  }

  const rawConfig = await readFile(filePath, "utf8");
  return JSON.parse(rawConfig);
};

const getPort = (scope, name) => PORTS[`${scope}:${name}`];

const getExpectedTargetServer = (scope, name, server) => {
  const port = getPort(scope, name);

  if (server.type !== "stdio" || !server.command || !port) {
    return undefined;
  }

  return {
    type: "http",
    url: getBridgeUrl(port),
  };
};

const syncTargetConfig = async (sourceConfig, sourceMcpConfig) => {
  const targetConfig = (await readConfig(sourceConfig.targetFilePath)) ?? {};
  const nextServers = {
    ...(targetConfig.servers ?? {}),
  };
  const updates = [];

  for (const [name, server] of Object.entries(sourceMcpConfig.servers ?? {})) {
    const expectedServer = getExpectedTargetServer(
      sourceConfig.scope,
      name,
      server,
    );

    if (!expectedServer) {
      continue;
    }

    const currentServer = targetConfig.servers?.[name];

    if (
      stableStringify(currentServer ?? null) !== stableStringify(expectedServer)
    ) {
      nextServers[name] = expectedServer;
      updates.push(name);
    }
  }

  const nextConfig = {
    ...targetConfig,
    servers: nextServers,
  };

  if (
    targetConfig.inputs === undefined &&
    sourceMcpConfig.inputs !== undefined
  ) {
    nextConfig.inputs = sourceMcpConfig.inputs;
  }

  if (updates.length > 0) {
    await mkdir(path.dirname(sourceConfig.targetFilePath), { recursive: true });
    await writeFile(
      sourceConfig.targetFilePath,
      serializeConfig(nextConfig),
      "utf8",
    );
  }

  return { config: nextConfig, updates };
};

const resolveServer = (server, workspaceFolder) => {
  if (!server.command) {
    return { unresolved: ["missing:command"], missingEnv: [] };
  }

  const unresolved = new Set();
  const resolvedCommand = resolveTemplate(server.command, workspaceFolder);
  resolvedCommand.unresolved.forEach((value) => unresolved.add(value));

  const resolvedArgs = (server.args ?? []).map((arg) => {
    const resolvedArg = resolveTemplate(arg, workspaceFolder);
    resolvedArg.unresolved.forEach((value) => unresolved.add(value));
    return resolvedArg.resolved;
  });

  const resolvedEnvEntries = Object.entries(server.env ?? {}).map(
    ([envKey, envValue]) => {
      const resolvedEnvValue = resolveTemplate(
        envValue,
        workspaceFolder,
        envKey,
      );
      resolvedEnvValue.unresolved.forEach((value) => unresolved.add(value));
      return [envKey, resolvedEnvValue.resolved];
    },
  );

  const resolvedEnv = {
    ...process.env,
    ...Object.fromEntries(resolvedEnvEntries),
  };

  const missingEnv = (server.requiredEnv ?? []).filter((envName) => {
    const envValue = resolvedEnv[envName];
    return envValue === undefined || envValue === "";
  });

  if (unresolved.size > 0) {
    return { unresolved: [...unresolved], missingEnv };
  }

  if (missingEnv.length > 0) {
    return { unresolved: [], missingEnv };
  }

  return {
    config: {
      command: resolvedCommand.resolved,
      args: resolvedArgs,
      env: resolvedEnv,
    },
    unresolved: [],
    missingEnv: [],
  };
};

const healthCheck = async (port) =>
  new Promise((resolve) => {
    const request = http.get(
      {
        hostname: "127.0.0.1",
        port,
        path: "/healthz",
        timeout: 1000,
      },
      (response) => {
        const isHealthy = response.statusCode === 200;
        response.resume();
        resolve(isHealthy);
      },
    );

    request.on("error", () => resolve(false));
    request.on("timeout", () => {
      request.destroy();
      resolve(false);
    });
  });

const waitForHealthy = async (port) => {
  for (let attempt = 0; attempt < 20; attempt += 1) {
    if (await healthCheck(port)) {
      return true;
    }

    await new Promise((resolve) => setTimeout(resolve, 500));
  }

  return false;
};

const startBridge = async (scope, name, port, config, cwd) => {
  const logPath = path.join(
    logDir,
    `${sanitizeFileName(scope)}-${sanitizeFileName(name)}.log`,
  );
  const quotedCommand = [config.command, ...config.args]
    .map(shellQuote)
    .join(" ");
  const outputFd = openSync(logPath, "a");

  const child = spawn(
    "npx",
    [
      "-y",
      "supergateway",
      "--stdio",
      quotedCommand,
      "--outputTransport",
      "streamableHttp",
      "--port",
      String(port),
      "--streamableHttpPath",
      "/mcp",
      "--healthEndpoint",
      "/healthz",
      "--logLevel",
      "none",
      "--stateful",
    ],
    {
      cwd,
      detached: true,
      stdio: ["ignore", outputFd, outputFd],
      env: config.env,
    },
  );

  child.unref();
};

const collectStatus = async (sourceConfig, sourceMcpConfig, targetConfig) => {
  const statusLines = [];

  for (const [name, server] of Object.entries(sourceMcpConfig.servers ?? {})) {
    const port = getPort(sourceConfig.scope, name);
    const expectedServer = getExpectedTargetServer(
      sourceConfig.scope,
      name,
      server,
    );

    if (!port || !expectedServer) {
      continue;
    }

    const actualServer = targetConfig?.servers?.[name];
    const configState =
      stableStringify(actualServer ?? null) === stableStringify(expectedServer)
        ? "config-ok"
        : `config-drift expected ${JSON.stringify(expectedServer)} actual ${JSON.stringify(actualServer ?? null)}`;
    const healthState = (await healthCheck(port)) ? "healthy" : "down";

    statusLines.push(
      `${healthState} ${sourceConfig.scope}/${name}: ${getBridgeUrl(port)} (${configState})`,
    );
  }

  return statusLines;
};

const run = async () => {
  await mkdir(logDir, { recursive: true });

  const summary = [];
  let hasStartupError = false;

  for (const sourceConfig of sourceConfigs) {
    const mcpConfig = await readConfig(sourceConfig.filePath);

    if (!mcpConfig?.servers) {
      continue;
    }

    if (isStatusOnly) {
      const targetConfig = await readConfig(sourceConfig.targetFilePath);
      summary.push(
        ...(await collectStatus(sourceConfig, mcpConfig, targetConfig)),
      );
      continue;
    }

    const syncResult = await syncTargetConfig(sourceConfig, mcpConfig);

    if (syncResult.updates.length > 0) {
      summary.push(
        `synced ${sourceConfig.scope} config: ${syncResult.updates.join(", ")} -> ${sourceConfig.targetFilePath}`,
      );
    }

    for (const [name, server] of Object.entries(mcpConfig.servers)) {
      if (server.type !== "stdio" || !server.command) {
        continue;
      }

      const port = getPort(sourceConfig.scope, name);

      if (!port) {
        summary.push(
          `skip ${sourceConfig.scope}/${name}: missing port mapping`,
        );
        continue;
      }

      if (await healthCheck(port)) {
        summary.push(`ok ${sourceConfig.scope}/${name}: ${getBridgeUrl(port)}`);
        continue;
      }

      const resolvedServer = resolveServer(
        server,
        sourceConfig.workspaceFolder,
      );

      if (resolvedServer.missingEnv.length > 0) {
        summary.push(
          `skip ${sourceConfig.scope}/${name}: missing env ${resolvedServer.missingEnv.join(", ")}`,
        );
        continue;
      }

      if (!resolvedServer.config) {
        summary.push(
          `skip ${sourceConfig.scope}/${name}: unresolved ${resolvedServer.unresolved.join(", ")}`,
        );
        continue;
      }

      if (isDryRun) {
        summary.push(
          `dry-run ${sourceConfig.scope}/${name}: ${getBridgeUrl(port)}`,
        );
        continue;
      }

      await startBridge(
        sourceConfig.scope,
        name,
        port,
        resolvedServer.config,
        sourceConfig.cwd,
      );

      if (await waitForHealthy(port)) {
        summary.push(
          `started ${sourceConfig.scope}/${name}: ${getBridgeUrl(port)}`,
        );
      } else {
        summary.push(
          `failed ${sourceConfig.scope}/${name}: health check did not pass on port ${port}`,
        );
        hasStartupError = true;
      }
    }
  }

  if (isStatusOnly) {
    summary.push(
      "note: VS Code marks a server as Running when VS Code starts or connects to it from its own MCP lifecycle, for example via MCP: List Servers > Start or when chat uses that server. Bridge health alone does not flip that label.",
    );
  }

  summary.forEach((line) => console.log(line));

  if (hasStartupError) {
    process.exitCode = 1;
  }
};

run().catch((error) => {
  const message = error instanceof Error ? error.message : String(error);
  console.error(message);
  process.exit(1);
});
