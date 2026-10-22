'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const CODE = fs.readFileSync(path.join(__dirname, '..', 'gaptex.js'), 'utf8');

function makeFixture({ managersExist = true, stored = undefined } = {}) {
  const storage = new Map();
  if (stored) storage.set('gaptex:settings:v1', JSON.stringify(stored));
  const menus = [];
  const listeners = new Map();
  const intervals = [];
  const node = { id: 'gaptex-ad-style', textContent: '', remove() { elements.delete(this.id); } };
  const elements = new Map();
  const calls = { disable: 0, shuffle: [], notifications: [] };
  let shuffle = true;
  class MenuItem {
    constructor(name, enabled, callback) { this.name = name; this.enabled = enabled; this.callback = callback; }
    register() { menus.push(this); }
    setState(value) { this.enabled = value; }
    setName(value) { this.name = value; }
    click() { this.callback(this); }
  }
  const manager = { disable: async () => { calls.disable += 1; } };
  const platform = {
    ...(managersExist ? { AdManagers: { audio: manager, billboard: manager } } : {}),
  };
  const Spicetify = {
    Platform: platform,
    Player: {
      getShuffle() { return shuffle; },
      async setShuffle(flag) { calls.shuffle.push(flag); shuffle = flag; },
      addEventListener(name, callback) { listeners.set(name, callback); },
    },
    LocalStorage: {
      get(key) { return storage.get(key); },
      set(key, value) { storage.set(key, value); },
    },
    Menu: { Item: MenuItem },
    showNotification(msg) { calls.notifications.push(msg); },
  };
  const sandbox = {
    Spicetify,
    setTimeout() { throw Error('Unexpected retry'); },
    setInterval(callback, delay) { intervals.push({ callback, delay }); },
    document: {
      head: { appendChild(el) { elements.set(el.id, el); } },
      getElementById(id) { return elements.get(id) || null; },
      createElement(type) { assert.equal(type, 'style'); return { ...node }; },
    },
    console: { info() {}, warn() {} },
  };
  vm.runInNewContext(CODE, sandbox, { filename: 'gaptex.js' });
  return { Spicetify, menus, calls, storage, elements, listeners, intervals,
    get shuffle() { return shuffle; },
    set shuffle(value) { shuffle = value; } };
}

test('initialization creates exactly three profile toggles and ad CSS', async () => {
  const app = makeFixture();
  assert.equal(app.menus.length, 3);
  assert.equal(app.menus[0].name, 'Gaptex · AdBlock');
  assert.equal(app.menus[1].name, 'Gaptex · Anti-Reshuffle');
  assert.equal(app.menus[2].name, 'Gaptex · Shuffle yang dikunci: OFF');
  assert.equal(app.elements.has('gaptex-ad-style'), true);
  assert.equal(app.intervals.length, 2);
  await new Promise(setImmediate);
  assert.ok(app.calls.disable >= 2);
  assert.deepEqual(app.calls.shuffle, [false]);
});

test('turning AdBlock off removes CSS and retains shuffle settings', () => {
  const app = makeFixture();
  app.menus[0].click();
  assert.equal(app.elements.size, 0);
  const settings = JSON.parse(app.storage.get('gaptex:settings:v1'));
  assert.equal(settings.adblock, false);
  assert.equal(settings.antiReshuffle, true);
});

test('shuffle state can be locked ON when desired', async () => {
  const app = makeFixture({ stored: { preferredShuffle: false, antiReshuffle: false, adblock: false } });
  app.menus[2].click(); // save desired ON
  app.menus[1].click(); // enable antiReshuffle
  await new Promise(setImmediate);
  assert.equal(app.menus[2].name, 'Gaptex · Shuffle yang dikunci: ON');
  assert.equal(app.menus[1].enabled, true);
  assert.equal(app.shuffle, true);
  assert.equal(app.calls.shuffle.length, 0);
});

test('songchange restores locked shuffle setting after external changes', async () => {
  const app = makeFixture({ stored: { antiReshuffle: true, preferredShuffle: true, adblock: false } });
  app.shuffle = false;
  app.listeners.get('songchange')();
  await new Promise(setImmediate);
  assert.equal(app.shuffle, true);
  assert.deepEqual(app.calls.shuffle, [true]);
});

test('AdBlock degrades gracefully when ad manager API is not available', () => {
  const app = makeFixture({ managersExist: false });
  assert.equal(app.menus.length, 3);
  assert.equal(app.elements.size, 1);
});

test('startup is idempotent', () => {
  const app = makeFixture();
  // second load must not re-register menus or timers
  const menusBefore = app.menus.length;
  const context = { Spicetify: app.Spicetify, setInterval() { throw Error('Reinitialized'); }, setTimeout() {}, document: {}, console };
  vm.runInNewContext(CODE, context, { filename: 'gaptex.js' });
  assert.equal(app.menus.length, menusBefore);
});
