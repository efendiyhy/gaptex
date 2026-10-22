'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const core = fs.readFileSync(path.join(root, 'install.ps1'), 'utf8');
const remote = fs.readFileSync(path.join(root, 'install-online.ps1'), 'utf8');
const notice = fs.readFileSync(path.join(root, 'docs', 'THIRD_PARTY_NOTICES.md'), 'utf8');

test('online installer downloads and calls the same core installer', () => {
  assert.match(remote, /install\.ps1/);
  assert.match(remote, /gaptex\.js/);
  assert.match(remote, /& \$scriptPath/);
  assert.match(remote, /THIRD_PARTY_NOTICES/);
});
test('installer clears console then displays rainbow cat and giant brand', () => {
  assert.match(core, /Clear-Host/);
  assert.match(core, /CAT PROTOCOL : ONLINE/);
  assert.match(core, /INSTRUMENTATION/);
  assert.match(core, /foreach \(\$phrase in \$phrases\)/);
  assert.match(core, /ForegroundColor/);
});
test('installer closes Spotify before patching', () => {
  const stop = core.indexOf('Stop-GaptexSpotify\n    # The first CLI run');
  const config = core.indexOf("@('config','extensions','gaptex.js')");
  assert.ok(stop !== -1 && config !== -1 && stop < config);
});
test('install uses explicit backup logic, consent before restoring', () => {
  assert.match(core, /@\('apply','--no-restart'\)/);
  assert.match(core, /@\('backup','apply','--no-restart'\)/);
  assert.match(core, /Request-GaptexRestore/);
  assert.match(core, /@\('restore','backup','apply','--no-restart'\)/);
});
test('Windows native commands collect stderr and stdout separately', () => {
  assert.match(core, /RedirectStandardOutput/);
  assert.match(core, /RedirectStandardError/);
  assert.match(core, /ExitCode/);
  assert.doesNotMatch(core, /\*>>/);
});
test('project documents runtime and license, no third party binary bundled', () => {
  assert.match(notice, /Spicetify CLI/);
  assert.match(notice, /LGPL-2\.1/);
  assert.ok(!fs.existsSync(path.join(root, 'spicetify.exe')));
});
