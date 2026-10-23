'use strict';
const test=require('node:test');const assert=require('node:assert/strict');
const fs=require('node:fs'),path=require('node:path');
const root=path.resolve(__dirname,'..');
const core=fs.readFileSync(path.join(root,'install.ps1'),'utf8');
const online=fs.readFileSync(path.join(root,'install-online.ps1'),'utf8');
test('online installer retrieves both source and core script',()=>{
  assert.match(online,/foreach \(\$filename in @\('install.ps1', 'gaptex.js'\)\)/);
  assert.match(online,/& \(Join-Path \$work 'install.ps1'\)/);
});
test('installs real Spicetify official runtime and retains notices',()=>{
  assert.match(core,/spicetify\/cli\/main\/install.ps1/);
  assert.match(core,/Spicetify CLI resmi/);
  assert.match(fs.readFileSync(path.join(root,'docs/THIRD_PARTY_NOTICES.md'),'utf8'),/LGPL-2.1/);
  assert.ok(!fs.existsSync(path.join(root,'spicetify.exe')));
});
test('uses no destructive automatic reinstall or restore',()=>{
  assert.doesNotMatch(core,/Invoke-Native[^\n]+@\('restore'/);
  assert.doesNotMatch(core,/winget uninstall|Remove-Item.*Spotify/i);
  assert.match(core,/cannot be backed up at this state/i);
});
test('does not clear extension list or clobber other extensions',()=>{
  assert.match(core,/@\('config','extensions','gaptex.js'\)/);
  assert.doesNotMatch(core,/config extensions ""|config extensions ''/);
});
test('logs errors and stops only Spotify processes for activation',()=>{
  assert.match(core,/Stop-Process -Id \$p.Id -Force/);
  assert.match(core,/StandardOutput\.ReadToEndAsync/);
  assert.match(core,/ExitCode/);
});
test('previous backup failure is handled before retries',()=>{
  assert.match(core,/if \(\$apply.Text -match '\(\?i\)cannot be backed up at this state/);
  assert.match(core,/throw 'Spotify memerlukan instalasi ulang/);
});
