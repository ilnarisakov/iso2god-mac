# ISO2GOD

Mac app that converts an Xbox 360 `.iso` into **Games on Demand** (GOD) for Freeboot consoles and fetches
cover art for the **Aurora** dashboard. / Приложение для macOS: конвертирует Xbox 360 `.iso` в формат
Games on Demand (Freeboot) и подготавливает обложки для Aurora.

## Возможности
- Перетащили `.iso`, выбрали папку, нажали «Генерация». Внутри папки создаётся подпапка с именем игры.
- Обложка скачивается по Title ID с xboxunity.net и сохраняется как `GC<TitleID>.asset` в общую папку обложек
  (путь выбирается один раз, меняется в окне).
- Кнопка «Добавить обложки на флешку…» раскладывает `.asset` по `Aurora/Data/GameData/<TitleID>_<номер>/`.
  Нужен FAT32-диск и предварительное сканирование игры в Aurora (номер присваивает сама Aurora).
- Подробная инструкция есть в приложении (кнопка «Инструкция»).

## Быстрый старт
1. Соберите приложение (см. ниже) и откройте `ISO2GOD.app`.
2. Перетащите `.iso`, выберите папку, нажмите «Генерация». Папку игры скопируйте на флешку.
3. Просканируйте игру в Aurora на консоли, вставьте флешку в Mac и нажмите «Добавить обложки на флешку…».

## Сборка
Нужны полный Xcode (Command Line Tools недостаточно: SwiftUI-макросы) и Rust (`brew install rust`).

    ./build.sh

Результат: `ISO2GOD.app`. Подпись ad-hoc, при первом запуске: правый клик → «Открыть».

## Приватность
- Приложение не собирает и не отправляет персональные данные, в нём нет аналитики.
- Единственный сетевой запрос: Title ID игры (8 hex-символов) отправляется на xboxunity.net за обложкой.
- Локально хранится только путь к папке обложек (UserDefaults).

## Важно
Репозиторий не содержит игр и образов. Используйте собственные резервные копии дисков.

## Что использовано
| Компонент | Для чего | Источник |
|---|---|---|
| iso2god-rs | конвертация ISO → GOD | https://github.com/iliazeus/iso2god-rs (MIT) |
| libaustralis | клиент XboxUnity и запись `.asset` | https://github.com/jrobiche/libaustralis (GPL-3.0) |
| AuroraAssetEditor | описание формата `.asset` и имён файлов (`GC<TitleID>.asset`) | https://github.com/XboxUnity/AuroraAssetEditor |
| XboxUnity | источник обложек | https://xboxunity.net |
| SwiftUI | интерфейс | Apple |

## Лицензии
Проект распространяется под **GPL-3.0-or-later** (см. `LICENSE`), потому что использует
[libaustralis](https://github.com/jrobiche/libaustralis) (GPL-3.0).
Для конвертации используется [iso2god-rs](https://github.com/iliazeus/iso2god-rs) (MIT).
Формат `.asset` описан в [AuroraAssetEditor](https://github.com/XboxUnity/AuroraAssetEditor).
