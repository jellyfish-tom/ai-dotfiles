#!/usr/bin/env node
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const [, , command, profileDir, ...args] = process.argv;

if (!command || !profileDir) {
  process.stderr.write('Usage: read-profile.mjs <command> <profileDir> [args...]\n');
  process.exit(1);
}

const profilePath = resolve(profileDir, 'profile.json');
const profile = JSON.parse(readFileSync(profilePath, 'utf8'));

const get = (obj, path) => path.split('.').reduce((acc, key) => acc?.[key], obj);

switch (command) {
  case 'setup-field': {
    const field = args[0];
    const value = get(profile, `setup.${field}`) ?? get(profile, `preset.${field}`);
    if (value === undefined) {
      process.exit(1);
    }
    process.stdout.write(String(value));
    break;
  }
  case 'preset-field': {
    const field = args[0];
    const value = get(profile, `setup.${field}`) ?? get(profile, `preset.${field}`);
    if (value === undefined) {
      process.exit(1);
    }
    process.stdout.write(String(value));
    break;
  }
  case 'validation-json': {
    const section = args[0];
    process.stdout.write(JSON.stringify(get(profile, `validation.${section}`) ?? {}));
    break;
  }
  case 'parity-pairs': {
    process.stdout.write(JSON.stringify(profile.parity?.pairs ?? []));
    break;
  }
  case 'id': {
    process.stdout.write(profile.id ?? '');
    break;
  }
  default:
    process.stderr.write(`Unknown command: ${command}\n`);
    process.exit(1);
}