import { mkdir, readFile } from 'node:fs/promises';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = fileURLToPath(new URL('../', import.meta.url));
const { version } = JSON.parse(await readFile(path.join(root, 'package.json'), 'utf8'));
const files = ['plugin.toml', 'window.luau', 'LICENSE', 'README.md', 'README.zh-CN.md', 'CONTRIBUTING.md', 'SECURITY.md', 'CHANGELOG.md', 'docs/readiness.md', 'docs/reference.md', 'docs/reference.zh-CN.md', 'package.json', 'package-lock.json', 'scripts/check.mjs', 'scripts/pack.mjs', 'tests/behavior.luau', '.editorconfig', '.gitignore', '.github/workflows/ci.yml'];
await mkdir(path.join(root, 'dist'), { recursive: true });
const archive = `dist/tern-grid-layout-${version}.tar.gz`;
execFileSync('tar', ['-czf', archive, ...files], { cwd: root, env: { ...process.env, COPYFILE_DISABLE: '1' } });
console.log(archive);
console.log(execFileSync('tar', ['-tzf', archive], { cwd: root, encoding: 'utf8' }));
