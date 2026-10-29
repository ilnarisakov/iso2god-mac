🇬🇧 **English** · 🇷🇺 [Русская версия](README.ru.md)

# ISO2GOD

A macOS app that converts an Xbox 360 `.iso` into **Games on Demand** (GOD) for Freeboot consoles and
fetches cover art for the **Aurora** dashboard.

## Features
- Drop an `.iso`, pick an output folder, press **Генерация** (Generate). A subfolder named after the game is created inside it.
- The cover is downloaded by Title ID from xboxunity.net and saved as `GC<TitleID>.asset` in a shared covers
  folder (chosen once, changeable in the window).
- **Add covers to the flash drive** copies the `.asset` files into `Aurora/Data/GameData/<TitleID>_<number>/`.
  Requires a FAT32 drive and the game being scanned by Aurora first (Aurora assigns the number itself).
- A step-by-step guide is built into the app (the "Инструкция" button).

> The interface is currently in Russian.

## Quick start
1. Build the app (see below) and open `ISO2GOD.app`.
2. Drop an `.iso`, choose a folder, press Generate. Copy the game folder to your flash drive.
3. Scan the game in Aurora on the console, plug the drive into the Mac and press "Add covers to the flash drive".

## Build
Requires full Xcode (Command Line Tools are not enough: SwiftUI macros) and Rust (`brew install rust`).

    ./build.sh

Output: `ISO2GOD.app`. It is ad-hoc signed, so on first launch use right-click → Open.

## Privacy
- The app collects and sends no personal data and has no analytics.
- The only network request: the game's Title ID (8 hex characters) is sent to xboxunity.net to look up a cover.
- Locally it stores only the covers folder path (UserDefaults).

## Disclaimer
This repository contains no games or disc images. Use your own backups.

## Credits
| Component | Purpose | Source |
|---|---|---|
| iso2god-rs | ISO → GOD conversion | https://github.com/iliazeus/iso2god-rs (MIT) |
| libaustralis | XboxUnity client and `.asset` writing | https://github.com/jrobiche/libaustralis (GPL-3.0) |
| AuroraAssetEditor | `.asset` format and file naming (`GC<TitleID>.asset`) | https://github.com/XboxUnity/AuroraAssetEditor |
| XboxUnity | cover art source | https://xboxunity.net |
| SwiftUI | user interface | Apple |

## License
Distributed under **GPL-3.0-or-later** (see `LICENSE`) because it uses
[libaustralis](https://github.com/jrobiche/libaustralis) (GPL-3.0).
