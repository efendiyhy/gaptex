# Third-party notices & runtime disclosure

This is a required technical disclosure for **Gaptex**. The README and normal installation progress emphasize the Gaptex product, but this document identifies external dependencies accurately. Do not delete it when publishing the repository.

## Spicetify CLI

- Project: **Spicetify CLI** — https://github.com/spicetify/cli
- License: **GNU Lesser General Public License v2.1 (LGPL-2.1)** — https://github.com/spicetify/cli/blob/main/LICENSE
- Function: Install and load Gaptex's JavaScript extension into Spotify Desktop. Gaptex uses the `Spicetify` JavaScript runtime APIs and CLI commands internally.
- Windows package identity: `Spicetify.Spicetify` (installed via Windows Package Manager/winget, **only after user consent** if missing).
- Installation location: Managed by the package manager; Gaptex JavaScript extension is placed at `%APPDATA%\spicetify\Extensions\gaptex.js`.

Spicetify is not developed, owned, or rebranded by Gaptex. Its license and upstream copyrights remain in force. Gaptex does not bundle, sublicense, or redistribute a modified copy of its CLI binary; the Windows installer asks for consent and then obtains it from the third-party package manager separately. If this distribution model changes, license obligations should be re-evaluated.

## Spotify Desktop

- Project/service: Spotify Desktop (proprietary third-party application).
- Gaptex is not affiliated with, sponsored by, or endorsed by Spotify AB or Spicetify contributors.
- Users must comply with Spotify's applicable terms. Some behavior may break after updates and ad blocking may be restricted by those terms.

## Gaptex

- Independent code: `gaptex.js`, installation scripts, documentation, and tests in this repository (MIT, see `LICENSE`).
- Gaptex does not imply ownership of Spotify or Spicetify branding, APIs, code, or trademarks.
- Third-party software remains subject to its own terms. Branding the installation flow as Gaptex does not convert it into a standalone runtime.
