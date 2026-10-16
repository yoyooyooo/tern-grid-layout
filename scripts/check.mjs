import assert from 'node:assert/strict';
import { readFile, readdir, stat } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { LuauState } from 'luau-web';

const root = fileURLToPath(new URL('../', import.meta.url));
const text = (name) => readFile(path.join(root, name), 'utf8');
const manifest = await text('plugin.toml');
const pkg = JSON.parse(await text('package.json'));
const lock = JSON.parse(await text('package-lock.json'));
const field = (key) => {
    const match = manifest.match(new RegExp(`^${key} = "([^"]+)"$`, 'm'));
    assert.ok(match, `Missing plugin field: ${key}`);
    return match[1];
};
assert.match(manifest, /^schema = 1$/m);
assert.equal(field('id'), 'grid-layout');
assert.equal(field('version'), pkg.version);
assert.equal(lock.packages[''].version, pkg.version);
assert.equal(pkg.license, 'MIT');
assert.equal(pkg.private, true);
const source = await text(field('window'));
const vm = await LuauState.createAsync();
try {
    vm.loadstring(source, 'window.luau', true);
    const run = vm.loadstring(`local function load_plugin(tern)\n${source}\nend\n${await text('tests/behavior.luau')}`, 'behavior.luau', true);
    const [cases] = await run();
    console.log(`Luau compilation and ${cases} behavior scenarios passed.`);
} finally {
    vm.destroy();
}

async function walk(dir = '') {
    const result = [];
    for (const item of await readdir(path.join(root, dir), { withFileTypes: true })) {
        if (['.git', 'node_modules', 'dist'].includes(item.name)) continue;
        const name = path.posix.join(dir, item.name);
        if (item.isDirectory()) result.push(...await walk(name));
        else result.push(name);
    }
    return result;
}
const files = await walk();
const slug = (heading) => heading.toLowerCase().replace(/[`*_]/g, '')
    .replace(/[^\p{L}\p{N}\p{M}\s_-]/gu, '').replace(/ /g, '-');
let links = 0;
for (const name of files) {
    const content = await text(name);
    assert.ok(!/\/(?:Users|home)\/[a-z0-9_.-]+\//i.test(content), `${name}: machine home path`);
    assert.ok(!/(?:gh[pousr]_[a-zA-Z0-9]{20,}|github_pat_[a-zA-Z0-9_]{20,}|-----BEGIN (?:RSA |OPENSSH )?PRIVATE KEY-----)/.test(content), `${name}: credential pattern`);
    if (!name.endsWith('.md')) continue;
    const body = content.replace(/^```[^\n]*\n[\s\S]*?^```/gm, '');
    for (const match of body.matchAll(/\[[^\]]*\]\(([^\s)]+)\)/g)) {
        const href = match[1];
        if (/^[a-z]+:/i.test(href)) continue;
        const [file, anchor] = href.split('#');
        const target = path.resolve(root, path.dirname(name), decodeURIComponent(file || path.basename(name)));
        assert.ok(target.startsWith(root), `${name}: escaping link ${href}`);
        assert.ok((await stat(target)).isFile(), `${name}: invalid link ${href}`);
        if (anchor) {
            const headings = [...(await readFile(target, 'utf8')).matchAll(/^#{1,6}\s+(.+)$/gm)].map((m) => slug(m[1]));
            assert.ok(headings.includes(decodeURIComponent(anchor)), `${name}: missing anchor ${href}`);
        }
        links += 1;
    }
}
console.log(`Manifest versions match; ${links} local documentation links resolve; ${files.length} files scanned.`);
