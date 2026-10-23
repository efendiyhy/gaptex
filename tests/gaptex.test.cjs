'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const src = fs.readFileSync(require('node:path').join(__dirname,'..','gaptex.js'),'utf8');
function rig(initial = {}) {
  const settings = new Map();
  if (Object.keys(initial).length) settings.set('gaptex:settings:v2', JSON.stringify(initial));
  const items = [];
  const events = new Map();
  const timers = [];
  let shuffle = true;
  const calls = [];
  const elements = new Map();
  const head = { appendChild(el) { elements.set(el.id,el); } };
  class MenuItem {
    constructor(name, state, cb) { this.name=name; this.isEnabled=state; this.cb=cb; items.push(this); }
    register() { this.registered=true; }
    setName(s) { this.name=s; }
    setState(s) { this.isEnabled=s; }
    click() { this.cb(); }
  }
  const sp = {
    Menu:{ Item:MenuItem },
    LocalStorage:{ get:k=>settings.get(k), set:(k,v)=>settings.set(k,v) },
    Player:{ getShuffle:()=>shuffle, setShuffle:b=>{calls.push(b); shuffle=b;},
      addEventListener:(n,cb)=>events.set(n,cb) },
    Platform:{AdManagers:{audio:{disable:()=>{calls.push('disable-ad');}}}},
    showNotification:()=>{}
  };
  const ctx={Spicetify:sp, console:{info(){},warn(){},error(){}},
    Date:{ now: () => Date.now() }, setTimeout:()=>{},
    setInterval:fn=>{timers.push(fn);}, document:{head, getElementById:id=>elements.get(id),
    createElement:()=>({remove(){elements.delete(this.id);}})} };
  ctx.globalThis=ctx;
  vm.runInNewContext(src,ctx,{filename:'gaptex.js'});
  return {sp,items,events,timers,calls,settings,elements,setShuffle:b=>shuffle=b,getShuffle:()=>shuffle};
}
test('registers three items in Spotify profile menu',()=>{
  const r=rig(); assert.equal(r.items.length,3);
  assert.ok(r.items.every(i=>i.registered));
  assert.ok(r.items.some(i=>i.name.includes('Anti-Reshuffle')));
});
test('enforces default shuffle OFF', async()=>{
  const r=rig(); await Promise.resolve();
  assert.ok(r.calls.includes(false));
});
test('allows target shuffle ON and saves choice', async()=>{
  const r=rig(); r.items[2].click();
  const prefs=JSON.parse(r.settings.get('gaptex:settings:v2'));
  assert.equal(prefs.desiredShuffle,true);
  assert.match(r.items[2].name,/ ON$/);
});
test('disabling anti-reshuffle prevents automatic changes',()=>{
  const r=rig(); r.items[1].click();
  r.calls.length=0; r.setShuffle(true); r.timers[0]();
  assert.ok(!r.calls.includes(false));
});
test('adds removable CSS for UI filtering',()=>{
  const r=rig(); assert.ok(r.elements.has('gaptex-ad-styles'));
  r.items[0].click(); assert.ok(!r.elements.has('gaptex-ad-styles'));
});
test('uses documented Spicetify wrapper rather than premium spoofing',()=>{
  assert.match(src, /new sp.Menu.Item/);
  assert.match(src, /sp.Player.setShuffle/);
  assert.doesNotMatch(src,/putOverridesValues|catalogue.*premium/);
});
