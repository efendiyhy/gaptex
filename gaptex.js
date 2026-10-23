// NAME: Gaptex
// AUTHOR: EK Instrumentation
// DESCRIPTION: Shuffle mode lock and experimental ad filtering for Spicetify.
// VERSION: 0.3.0
// SPDX-License-Identifier: MIT
(function gaptexBootstrap(tries) {
  'use strict';
  if (!Number.isInteger(tries)) tries = 0;
  const sp = globalThis.Spicetify;
  // An extension is loaded by Spicetify, not injected through a separate app.
  if (!sp?.Player || !sp?.Menu?.Item || !sp?.LocalStorage) {
    if (tries < 100) setTimeout(() => gaptexBootstrap(tries + 1), 200);
    else console.error('[Gaptex] Spicetify API was not ready.');
    return;
  }
  if (sp.__gaptexInitialized) return;
  sp.__gaptexInitialized = true;

  const KEY = 'gaptex:settings:v2';
  const STYLE_ID = 'gaptex-ad-styles';
  const DEFAULTS = { adblock: true, antiReshuffle: true, desiredShuffle: false };
  const selectors = [
    '[data-testid="home-ads-container"]', '[data-testid="home-ad-card"]',
    '[data-testid="billboard-minimized"]', '[data-testid="billboard-image-link"]',
    '[data-testid="leaderboard-ad"]', '[data-testid="html-hpto-container"]',
    '[data-testid="hpto-parent-container"]', '[data-testid="hpto-native"]',
    '[data-testid="signup-bar"]', '#leaderboard-ad-element',
    '#view-billboard-ad', '.main-leaderboardComponent-container',
    '.sponsor-container', '.main-topBar-UpgradeButton'
  ];
  const log = (...x) => console.info('[Gaptex]', ...x);
  const warn = (...x) => console.warn('[Gaptex]', ...x);
  let prefs = { ...DEFAULTS };
  try {
    const saved = JSON.parse(sp.LocalStorage.get(KEY) || '{}');
    for (const key of Object.keys(DEFAULTS)) {
      if (typeof saved[key] === 'boolean') prefs[key] = saved[key];
    }
  } catch (e) { warn('Saved settings were invalid; using defaults.'); }
  function persist() {
    try { sp.LocalStorage.set(KEY, JSON.stringify(prefs)); }
    catch (e) { warn('Cannot save preferences:', e); }
  }
  function toast(msg) {
    try { sp.showNotification?.(`Gaptex: ${msg}`); }
    catch (e) { log(msg); }
  }

  // This is best effort. Spotify may display server-side audio ads despite this.
  function setAdCss() {
    const doc = globalThis.document;
    if (!doc?.head) return;
    let style = doc.getElementById(STYLE_ID);
    if (!prefs.adblock && style) { style.remove(); return; }
    if (prefs.adblock && !style) {
      style = doc.createElement('style');
      style.id = STYLE_ID;
      style.textContent = `${selectors.join(',\n')} { display: none !important; }`;
      doc.head.appendChild(style);
    }
  }
  let adRunning = false;
  let adWarningShown = false;
  async function tryAdFilter() {
    setAdCss();
    if (!prefs.adblock || adRunning) return;
    const managers = sp.Platform?.AdManagers;
    if (!managers) {
      if (!adWarningShown) {
        adWarningShown = true;
        warn('Audio AdManagers API unavailable. Only visible ad containers will be filtered.');
      }
      return;
    }
    adRunning = true;
    try {
      const targets = [managers.audio, managers.billboard, managers.inStreamApi,
        managers.sponsoredPlaylist, managers.embeddedAd?.embeddedAdManager,
        managers.vto?.manager];
      for (const manager of targets) {
        if (typeof manager?.disable === 'function') {
          try { await manager.disable(); } catch (e) { warn('Ad manager unavailable:', e); }
        }
      }
      if (typeof managers.leaderboard?.disableLeaderboard === 'function') {
        try { await managers.leaderboard.disableLeaderboard(); } catch (e) { warn('Leaderboard:', e); }
      }
    } finally { adRunning = false; }
  }

  let pendingShuffle = false;
  let lastSetAt = 0;
  async function enforceShuffle() {
    if (!prefs.antiReshuffle || pendingShuffle || typeof sp.Player?.getShuffle !== 'function') return;
    let current;
    try { current = sp.Player.getShuffle(); } catch (e) { return; }
    if (typeof current !== 'boolean' || current === prefs.desiredShuffle) return;
    const now = Date.now();
    if (now - lastSetAt < 1200) return;
    pendingShuffle = true;
    lastSetAt = now;
    try {
      if (typeof sp.Player.setShuffle === 'function') {
        await sp.Player.setShuffle(prefs.desiredShuffle);
      } else if (typeof sp.Platform?.PlayerAPI?.setShuffle === 'function') {
        await sp.Platform.PlayerAPI.setShuffle(prefs.desiredShuffle);
      } else warn('Shuffle setter unavailable on this Spotify build.');
    } catch (e) { warn('Could not enforce shuffle:', e); }
    finally { pendingShuffle = false; }
  }

  const adItem = new sp.Menu.Item('Gaptex - AdBlock (experimental)', prefs.adblock, () => {
    prefs.adblock = !prefs.adblock; persist(); adItem.setState(prefs.adblock);
    setAdCss();
    if (prefs.adblock) void tryAdFilter();
    toast(prefs.adblock ? 'AdBlock enabled (best effort)' : 'AdBlock disabled; restart Spotify to restore ad managers');
  });
  adItem.register();
  const shuffleItem = new sp.Menu.Item('Gaptex - Anti-Reshuffle', prefs.antiReshuffle, () => {
    prefs.antiReshuffle = !prefs.antiReshuffle; persist();
    shuffleItem.setState(prefs.antiReshuffle);
    if (prefs.antiReshuffle) void enforceShuffle();
    toast(prefs.antiReshuffle ? 'Shuffle lock ON' : 'Shuffle lock OFF');
  });
  shuffleItem.register();
  const targetItem = new sp.Menu.Item(`Gaptex - Target shuffle ${prefs.desiredShuffle ? 'ON' : 'OFF'}`, prefs.desiredShuffle, () => {
    prefs.desiredShuffle = !prefs.desiredShuffle; persist();
    targetItem.setState(prefs.desiredShuffle);
    targetItem.setName(`Gaptex - Target shuffle ${prefs.desiredShuffle ? 'ON' : 'OFF'}`);
    void enforceShuffle();
    toast(`Shuffle target ${prefs.desiredShuffle ? 'ON' : 'OFF'}`);
  });
  targetItem.register();

  persist();
  void tryAdFilter();
  void enforceShuffle();
  if (typeof sp.Player.addEventListener === 'function') {
    sp.Player.addEventListener('songchange', () => { void enforceShuffle(); void tryAdFilter(); });
  }
  setInterval(() => { void enforceShuffle(); }, 3000);
  setInterval(() => { void tryAdFilter(); }, 20000);
  log('v0.3.0 loaded. Open your Spotify profile menu for Gaptex.');
})();
