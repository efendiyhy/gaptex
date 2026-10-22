// NAME: Gaptex
// AUTHOR: Gaptex contributors
// DESCRIPTION: Two focused Spotify Desktop features: ad filtering and anti-reshuffle.
// VERSION: 0.1.5
// SPDX-License-Identifier: MIT
//
// This is an independent, readable implementation; it does not include
// upstream Spicetify CLI code or the Adblockify extension.
// No third-party endpoints, trackers, or remote code execution.

(function bootGaptex() {
  "use strict";

  const VERSION = "0.1.5";
  const SETTINGS_KEY = "gaptex:settings:v1";
  const CSS_ID = "gaptex-ad-style";
  const DEFAULTS = Object.freeze({
    adblock: true,
    antiReshuffle: true,
    preferredShuffle: false,
  });
  const AD_CSS = `
    [data-testid="home-ads-container"],
    [data-testid="home-ad-card"],
    [data-testid="billboard-minimized"],
    [data-testid="billboard-image-link"],
    [data-testid="leaderboard-ad"],
    [data-testid="html-hpto-container"],
    [data-testid="hpto-parent-container"],
    [data-testid="hpto-native"],
    [data-testid="hpto-image"],
    [data-testid="signup-bar"],
    [data-testid="upgrade-button"],
    #leaderboard-ad-element,
    #view-billboard-ad,
    .main-leaderboardComponent-container,
    .sponsor-container,
    .main-topBar-UpgradeButton {
      display: none !important;
    }
  `;

  let sp;
  try {
    sp = typeof Spicetify !== "undefined" ? Spicetify : null;
  } catch (_) {
    sp = null;
  }
  if (!sp || !sp.Player || !sp.Platform || !sp.Menu?.Item) {
    setTimeout(bootGaptex, 300);
    return;
  }
  if (sp.__gaptexLoaded) return;
  sp.__gaptexLoaded = true;

  const log = (...args) => console.info("[Gaptex]", ...args);
  const warn = (...args) => console.warn("[Gaptex]", ...args);
  let settings = readSettings();
  let lastShuffleCommand = 0;
  let shuffleBusy = false;
  let adsBusy = false;
  let lastAdWarn = false;
  let lastAdAttempt = 0;
  let lastSlotCheck = 0;

  function readSettings() {
    try {
      const text = sp.LocalStorage?.get(SETTINGS_KEY);
      if (!text) return { ...DEFAULTS };
      const raw = JSON.parse(text);
      if (!raw || typeof raw !== "object") throw Error("Invalid settings");
      return {
        adblock: typeof raw.adblock === "boolean" ? raw.adblock : DEFAULTS.adblock,
        antiReshuffle: typeof raw.antiReshuffle === "boolean" ? raw.antiReshuffle : DEFAULTS.antiReshuffle,
        preferredShuffle: typeof raw.preferredShuffle === "boolean" ? raw.preferredShuffle : DEFAULTS.preferredShuffle,
      };
    } catch (_) {
      return { ...DEFAULTS };
    }
  }

  function saveSettings() {
    try {
      sp.LocalStorage?.set(SETTINGS_KEY, JSON.stringify(settings));
    } catch (error) {
      warn("Unable to save settings:", error);
    }
  }

  function notify(message) {
    try { sp.showNotification?.(message); } catch (_) { log(message); }
  }

  function ensureAdStyles() {
    if (!document?.head) return;
    let style = document.getElementById(CSS_ID);
    if (settings.adblock && !style) {
      style = document.createElement("style");
      style.id = CSS_ID;
      style.textContent = AD_CSS;
      document.head.appendChild(style);
    } else if (!settings.adblock && style) {
      style.remove();
    }
  }

  async function disableAdManager(manager) {
    if (!manager || typeof manager.disable !== "function") return false;
    try { await manager.disable(); return true; }
    catch (error) { warn("Ad manager disable failed:", error); return false; }
  }

  // Spotify's AdManagers are *internal*, version-dependent client APIs.
  // Check each method before calling it, and do not fake a Premium subscription.
  async function filterAds() {
    if (!settings.adblock || adsBusy) return;
    adsBusy = true;
    try {
      ensureAdStyles();
      const managers = sp.Platform?.AdManagers;
      if (!managers || Object.keys(managers).length === 0) {
        if (!lastAdWarn) {
          warn("Audio ad API unavailable: UI filtering remains active. This is not guaranteed to block audio ads.");
          lastAdWarn = true;
        }
        return;
      }
      lastAdWarn = false;
      // Change only the ads eligibility hint, not the user's account tier.
      // This native service is optional and may reject client overrides.
      const productState = sp.Platform.UserAPI?._product_state ||
        sp.Platform.UserAPI?._product_state_service ||
        sp.Platform.ProductStateAPI?.productStateApi;
      if (typeof productState?.putOverridesValues === "function") {
        try { await productState.putOverridesValues({ pairs: { ads: "0" } }); }
        catch (_) { /* No override support on this client/version. */ }
      }
      // Best-effort slot cleanup. Does not intercept network traffic or spoof
      // a premium subscription. Guard all shapes because they change.
      const now = Date.now();
      if (now - lastSlotCheck > 60000) {
        lastSlotCheck = now;
        const connector = managers.audio?.inStreamApi?.adsCoreConnector;
        if (typeof connector?.clearSlot === "function" && typeof sp.CosmosAsync?.get === "function") {
          try {
            const response = await sp.CosmosAsync.get("sp://ads/v1/slots");
            const slots = Array.isArray(response) ? response : response?.adSlots || [];
            for (const slot of slots) {
              const id = slot?.slotId || slot?.slot_id;
              if (id) await connector.clearSlot(id);
            }
          } catch (_) { /* The ad slots endpoint can be unavailable. */ }
        }
      }
      const targets = [
        managers.audio,
        managers.billboard,
        managers.sponsoredPlaylist,
        managers.inStreamApi,
        managers.embeddedAd?.embeddedAdManager,
        managers.vto?.manager,
      ];
      await Promise.all(targets.map(disableAdManager));
      try {
        if (typeof managers.leaderboard?.disableLeaderboard === "function") {
          await managers.leaderboard.disableLeaderboard();
        } else {
          await disableAdManager(managers.leaderboard);
        }
      } catch (error) { warn("Leaderboard disable failed:", error); }
      try {
        if (managers.audio && "isNewAdsNpvEnabled" in managers.audio) {
          managers.audio.isNewAdsNpvEnabled = false;
        }
        if (managers.vto && "isNewAdsNpvEnabled" in managers.vto) {
          managers.vto.isNewAdsNpvEnabled = false;
        }
      } catch (_) { /* Read-only fields vary between versions. */ }
    } finally {
      adsBusy = false;
    }
  }

  // Remember the user-selected mode and restore it when Spotify changes it.
  // This locks the shuffle *switch*, not the sequence of a remote Spotify queue.
  async function enforceShuffle() {
    if (!settings.antiReshuffle || shuffleBusy) return;
    let observed;
    try { observed = sp.Player.getShuffle?.(); }
    catch (_) { return; }
    if (typeof observed !== "boolean" || observed === settings.preferredShuffle) return;
    const now = Date.now();
    if (now - lastShuffleCommand < 1500) return;
    lastShuffleCommand = now;
    shuffleBusy = true;
    try {
      // The Spicetify wrapper is documented; a version-specific fallback is allowed.
      if (typeof sp.Player.setShuffle === "function") {
        await sp.Player.setShuffle(settings.preferredShuffle);
      } else if (typeof sp.Platform?.PlayerAPI?.setShuffle === "function") {
        await sp.Platform.PlayerAPI.setShuffle(settings.preferredShuffle);
      } else {
        warn("Shuffle control API unavailable.");
      }
    } catch (error) { warn("Cannot restore shuffle mode:", error); }
    finally { shuffleBusy = false; }
  }

  function menu(label, initial, callback) {
    const item = new sp.Menu.Item(label, initial, callback);
    item.register();
    return item;
  }

  const adMenu = menu("Gaptex · AdBlock", settings.adblock, () => {
    settings.adblock = !settings.adblock;
    saveSettings();
    adMenu.setState(settings.adblock);
    ensureAdStyles();
    if (settings.adblock) void filterAds();
    notify(settings.adblock ? "Gaptex AdBlock aktif (best effort)" : "Gaptex AdBlock nonaktif. Restart Spotify untuk pemulihan penuh.");
  });

  const antiMenu = menu("Gaptex · Anti-Reshuffle", settings.antiReshuffle, () => {
    settings.antiReshuffle = !settings.antiReshuffle;
    saveSettings();
    antiMenu.setState(settings.antiReshuffle);
    if (settings.antiReshuffle) void enforceShuffle();
    notify(settings.antiReshuffle ? "Gaptex mengunci mode shuffle pilihan." : "Gaptex tidak lagi mengunci shuffle.");
  });

  const desiredMenu = menu("Gaptex · Shuffle yang dikunci: OFF", settings.preferredShuffle, () => {
    settings.preferredShuffle = !settings.preferredShuffle;
    saveSettings();
    desiredMenu.setState(settings.preferredShuffle);
    desiredMenu.setName(`Gaptex · Shuffle yang dikunci: ${settings.preferredShuffle ? "ON" : "OFF"}`);
    if (settings.antiReshuffle) void enforceShuffle();
    notify(`Gaptex: mode shuffle target ${settings.preferredShuffle ? "ON" : "OFF"}.`);
  });
  desiredMenu.setName(`Gaptex · Shuffle yang dikunci: ${settings.preferredShuffle ? "ON" : "OFF"}`);

  saveSettings();
  ensureAdStyles();
  void filterAds();
  void enforceShuffle();

  // Events + a modest watchdog. No global fetch interception, no muting or
  // skipping playback, no modification to other extensions or Spotify files.
  sp.Player.addEventListener("songchange", () => {
    void enforceShuffle();
    if (settings.adblock && Date.now() - lastAdAttempt > 7000) {
      lastAdAttempt = Date.now();
      void filterAds();
    }
  });
  setInterval(() => {
    if (settings.antiReshuffle) void enforceShuffle();
  }, 3000);
  setInterval(() => {
    if (settings.adblock) void filterAds();
  }, 15000);

  log(`v${VERSION} loaded; adblock=${settings.adblock}; antiReshuffle=${settings.antiReshuffle}; preferredShuffle=${settings.preferredShuffle}`);
})();
