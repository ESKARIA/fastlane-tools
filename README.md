# Fastlane Tools

Общий набор Fastlane-лейнов для iOS/macOS-проектов ESKARIA: сборка, подпись через
`match`, загрузка в TestFlight и App Store, загрузка dSYM в AppMetrica/Firebase
Crashlytics и сбор метрик выполнения лейнов.

Уведомления о статусе сборки (Telegram и другие) больше не отправляются этим
репозиторием — эта ответственность полностью перенесена в relay-шаблоны
gitlab-ci/Messenger.

Репозиторий подключается к проекту-потребителю через `import_from_git` —
своего Fastfile с нуля писать не нужно, только минимальный конфиг с
переменными окружения проекта. Обновления пайплайна поставляются как
изменения `fastlane-tools`; версии фиксируются git-тегами (`vX.Y.Z`), поэтому
обновление не ломает существующие пайплайны, пока вы явно не смените тег.

## Оглавление

- [🚀 Быстрый старт: подключение к своему проекту](#-быстрый-старт-подключение-к-своему-проекту)
- [⚙️ Переменные окружения](#️-переменные-окружения)
- [🛤 Основные lane-ы](#-основные-lane-ы)
- [🤖 Пример CI (GitLab CI)](#-пример-ci-gitlab-ci)
- [🔄 Обновление версий](#-обновление-версий)
- [📚 Документация и требования](#-документация-и-требования)

## 🚀 Быстрый старт: подключение к своему проекту

### 1️⃣ Gemfile и Pluginfile проекта-потребителя

В корне вашего iOS/macOS-проекта создайте (или дополните) `Gemfile`:

```ruby
source 'https://rubygems.org'

gem 'fastlane'
gem 'rubyzip'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
```

И `fastlane/Pluginfile`:

```ruby
gem 'fastlane-plugin-versioning'
```

`fastlane-plugin-versioning` обязателен — лейны `build`/`version` используют его
экшены (`get_version_number_from_xcodeproj`, `increment_build_number_in_xcodeproj`
и т.д.).

Установите зависимости:

```bash
bundle install
```

### 2️⃣ Минимальный `fastlane/Fastfile` проекта

```ruby
# frozen_string_literal: true

default_platform(:ios)

import_from_git(
  url: 'git@github.com:ESKARIA/fastlane-tools.git',
  branch: 'v3.1.0', # пин на тег — обязательно для предсказуемых обновлений
  path: 'fastlane/Fastfile_match', # любой файл кроме Fastfile — во избежание рекурсивного импорта
  dependencies: [
    'fastlane/Fastfile_build',        # сборка iOS
    'fastlane/Fastfile_macos',        # сборка и публикация macOS (platform :mac)
    'fastlane/Fastfile_tests',        # запуск тестов
    'fastlane/Fastfile_dsyms',        # загрузка символов
    'fastlane/Fastfile_upload',       # загрузка в TestFlight
    'fastlane/Fastfile_appstore',     # работа с App Store
    'fastlane/Fastfile_create_app',   # создание приложения в App Store Connect
    'fastlane/Fastfile_helpers'       # retry-логика, метрики
  ]
)
```

Если macOS-пайплайн вам не нужен, `Fastfile_macos` из `dependencies` можно
убрать — на iOS-лейны это не влияет.

### 3️⃣ Минимальный набор обязательных переменных окружения

```bash
export APP_IDENTIFIER="com.company.appname"
export MAIN_TARGET="AppName"
export APP_VERSION="1.2.3"            # или ветка beta/1.2.3 / release/1.2.3 — версия определится автоматически
export CI_PIPELINE_IID="123"          # номер сборки (в GitLab CI подставляется автоматически)
export APPSTORE_KEY_ID="ABC123XYZ"
export APPSTORE_ISSUER_ID="12345678-1234-1234-1234-123456789012"
export APPSTORE_KEY_CONTENT="$(cat AuthKey_ABC123XYZ.p8 | base64)"
export MATCH_PASSWORD="пароль-шифрования-match-репозитория"
export MATCH_GIT_URL="git@github.com:your-org/certificates.git"
```

`MATCH_GIT_URL`, `MATCH_PASSWORD`, `MATCH_USERNAME` — стандартные переменные
плагина/экшена `match` (не объявляются в коде `fastlane-tools`, но
обязательны для его работы: без git-репозитория сертификатов `match`
генерировать/устанавливать профили не сможет).

### 4️⃣ Первая проверка

```bash
# Список всех доступных lane-ов (проверяет, что import_from_git отработал)
bundle exec fastlane lanes

# Установка сертификатов App Store из match-репозитория (readonly)
bundle exec fastlane match_install_appstore

# Если сертификатов ещё нет — сгенерировать
bundle exec fastlane match_generate_appstore
```

Если `fastlane lanes` показывает лейны `build`, `upload_testflight`,
`match_install_appstore` и т.д. — подключение выполнено верно.

## ⚙️ Переменные окружения

Все секреты (ключи API, пароли match) передаются только через переменные
CI/CD (protected/masked variables), не хранятся в репозитории проекта.

### Обязательные

| Переменная | Назначение |
|---|---|
| `APP_IDENTIFIER` | Bundle identifier приложения. Поддерживает несколько через запятую: `com.app.main,com.app.widget` |
| `MAIN_TARGET` | Название основного target для сборки |
| `APP_VERSION` | Маркетинговая версия (`1.2.3`). Если пусто, а сборка идёт из ветки `beta/1.2.3` или `release/1.2.3` — версия извлекается из имени ветки автоматически |
| `CI_PIPELINE_IID` | Номер сборки (используется как build number). В GitLab CI подставляется платформой автоматически |
| `APPSTORE_KEY_ID` | Key ID ключа App Store Connect API |
| `APPSTORE_ISSUER_ID` | Issuer ID App Store Connect API |
| `APPSTORE_KEY_CONTENT` | Содержимое `.p8`-ключа в Base64 |
| `MATCH_PASSWORD` | Пароль шифрования match-репозитория с сертификатами |
| `MATCH_GIT_URL` | URL git-репозитория, в котором `match` хранит сертификаты и профили (стандартная переменная `match`, а не `fastlane-tools`) |

### Опциональные

| Переменная | Значение по умолчанию | Назначение |
|---|---|---|
| `MAIN_PROJECT_FILE` | `{MAIN_TARGET}.xcodeproj` | Путь к `.xcodeproj`, если имя не совпадает с target |
| `BUILD_SCHEME` / `SCHEME` | значение `MAIN_TARGET` | Xcode-схема для сборки/тестов |
| `BUILD_CONFIGURATION` / `CONFIGURATION` | берётся из схемы | Конфигурация сборки (Release/Debug) |
| `ARTIFACTS_PATH` | `fastlane/artifacts/` (в корне проекта) | Каталог для IPA/dSYM/.pkg. Относительный путь резолвится от корня проекта (не от `fastlane/`), `~` разворачивается в HOME |
| `ARTIFACT_BASENAME` | значение `BUILD_SCHEME` | Базовое имя файлов артефактов: `{ARTIFACT_BASENAME}_v{APP_VERSION}_b{BUILD_NUMBER}` |
| `HELPER_PATH` / `APPMETRICA_HELPER_PATH` | `fastlane/helper` | Путь к helper-бинарю AppMetrica для загрузки dSYM |
| `APPMETRICA_KEY` | — | Ключ AppMetrica. Загрузка в AppMetrica включается только если заданы и ключ, и helper-бинарь по `HELPER_PATH` |
| `UPLOAD_DSYMS` | `true` (включено) | `false` отключает лейн `upload_dsyms` целиком |
| `EXTERNAL_TESTFLIGHT_GROUPS` | — | Если задано, `upload_testflight` автоматически грузит для external testers в указанные группы (через запятую) |
| `TAG_PREFIX` | — | Префикс git-тега в `tagging` (`{prefix}/v{VERSION}-build-{BUILD}`), полезно для монорепо с несколькими таргетами |
| `MATCH_USERNAME` / `ACCOUNT_EMAIL` | — | Логин Apple ID для `match`/Developer Portal (`FASTLANE_USER` берётся из первого непустого) |
| `TEAM_ID` / `FASTLANE_TEAM_ID` | — | Apple Developer Team ID |
| `MATCH_KEYCHAIN_NAME` | `fastlane_tmp_keychain` | Имя постоянного keychain для подписи на CI |
| `MATCH_KEYCHAIN_PASSWORD` | `''` (пусто) | Пароль keychain для подписи |
| `APPSTORE_KEY_PATH` / `APP_STORE_CONNECT_KEY_PATH` | — | Путь к файлу `.p8`, альтернатива `APPSTORE_KEY_CONTENT` (используется, например, в `check_released`/`upload_metadata`) |
| `DELIVER_METADATA_PATH` | Deliverfile / `./fastlane/metadata` | Путь к метаданным одного пака (для монорепо с несколькими приложениями) |
| `MACOS_MATCH_DEV_BRANCH` | `macos_development` | Ветка match-репозитория с development-сертификатами macOS |
| `MACOS_MATCH_DIST_BRANCH` | `macos_distribution` | Ветка match-репозитория с distribution-сертификатами macOS |
| `MAC_INSTALLER_CERT` | `3rd Party Mac Developer Installer` | Имя installer-сертификата для подписи `.pkg` |
| `CI` | — | Если задано (стандартно на CI-раннерах), выполняется дополнительная инициализация: `clear_derived_data`, настройка API-ключа в `before_all` |

## 🛤 Основные lane-ы

### 🔑 Сертификаты (`match`)

| Lane | Что делает |
|---|---|
| `match_generate_dev` | Генерирует development-сертификаты и профили (ветка `development`) |
| `match_generate_appstore` | Генерирует App Store сертификаты и профили (ветка `distribution`) |
| `match_install_dev` | Устанавливает development-сертификаты локально/на CI (readonly) |
| `match_install_appstore` | Устанавливает App Store сертификаты локально/на CI (readonly) |
| `reset_all_profiles` | Полностью перегенерирует development и appstore сертификаты |
| `nuke_development` / `nuke_appstore` / `nuke_all` | Необратимое удаление сертификатов и профилей |

### 🏗 Сборка

| Lane | Что делает |
|---|---|
| `version` | Устанавливает `APP_VERSION` в xcodeproj (и Info.plist, если он ещё используется) для `MAIN_TARGET` |
| `build` | Полный цикл: версия → build number → сертификаты → `build_app` → сохранение IPA/dSYM в `ARTIFACTS_PATH`, синхронизация версии встроенных таргетов (extensions/watch app) |

### ✈️ Загрузка в TestFlight (`Fastfile_upload`)

| Lane | Что делает |
|---|---|
| `upload_testflight` | Автоопределяет internal/external по `EXTERNAL_TESTFLIGHT_GROUPS`/параметру `external:true`. Параметр `groups:"Group1,Group2"` — группы external testers |
| `upload_external_testflight groups:"..."` | Явная загрузка для external testers, changelog берётся из git-коммитов с последнего тега |
| `tagging tags:true` | Создаёт git-тег `v{APP_VERSION}-build-{BUILD_NUMBER}` (или с `TAG_PREFIX`) |

### 🏪 App Store (`Fastfile_appstore`)

| Lane | Что делает |
|---|---|
| `pass_to_review` | Находит последнюю сборку в TestFlight и отправляет её на рецензирование в App Store, затем сливает release-ветку в `main` |
| `upload_metadata ver:2.0.0` | Заливает только текстовые метаданные (без бинаря/скриншотов); создаёт draft-версию, если редактируемой ещё нет |
| `check_released ver:2.8.3` | Проверяет статус версии в App Store Connect, пишет `release_status.json` в корень проекта |
| `create_app` | Создаёт новое приложение в App Store Connect (через `produce`) |

### 🧩 dSYM (`Fastfile_dsyms`)

| Lane | Что делает |
|---|---|
| `upload_dsyms firebase:true` | Загружает dSYM в AppMetrica (если заданы `APPMETRICA_KEY` и helper) и/или Firebase Crashlytics (`firebase:true`). Пропускается целиком при `UPLOAD_DSYMS=false` |

### 🧪 Тесты (`Fastfile_tests`)

| Lane | Что делает |
|---|---|
| `tests scheme:"AppNameTests" device:"iPhone 15"` | Запускает unit/UI-тесты на симуляторе, собирает code coverage |

### 🖥 macOS (`platform :mac`, `Fastfile_macos`)

Зеркалит iOS-пайплайн, но собирает `.pkg`, подписывает installer-сертификатом
и грузит с платформой `osx`. Сертификаты — в отдельных ветках match
(`macos_development`/`macos_distribution`). Вызывается с префиксом `mac`:

| Lane | Что делает |
|---|---|
| `mac match_generate_dev` | Генерирует development-сертификаты macOS |
| `mac match_generate_appstore` | Генерирует App Store + installer-сертификаты macOS |
| `mac match_install_appstore` | Устанавливает сертификаты macOS (readonly, для CI) |
| `mac build` | Собирает `.pkg` для App Store |
| `mac upload_testflight` / `mac upload_testflight external:true groups:"..."` | Загрузка в TestFlight, авто-определение internal/external как в iOS |
| `mac upload_appstore` / `mac upload_appstore submit:true` | Загрузка в App Store Connect, `submit:true` — сразу на рецензирование |

Переменные — те же, что для iOS (`APP_IDENTIFIER`, `APPSTORE_KEY_*`,
`MATCH_GIT_URL`, `MATCH_PASSWORD`, `MAIN_PROJECT_FILE`/`MAIN_TARGET`/
`BUILD_SCHEME`, `APP_VERSION`, `CI_PIPELINE_IID`), плюс опционально
`MAC_INSTALLER_CERT`, `MACOS_MATCH_DEV_BRANCH`, `MACOS_MATCH_DIST_BRANCH`.

### 🚚 macOS: прямая дистрибуция (`platform :mac`, `Fastfile_macos_direct`)

Отдельный пайплайн распространения приложения в обход App Store: подпись
Developer ID, сборка `.dmg`, нотаризация и генерация Sparkle-фида для
автообновлений. Сертификаты Developer ID хранятся в match на отдельной
ветке, не пересекающейся с `macos_development`/`macos_distribution`.
Вызывается с префиксом `mac`:

| Lane | Что делает |
|---|---|
| `mac match_generate_developer_id` | Генерирует Developer ID сертификаты (Application + Installer). Может выпускать только Account Holder аккаунта Apple Developer |
| `mac match_install_developer_id` | Устанавливает Developer ID сертификаты (readonly, для CI) |
| `mac build_direct` | Собирает `.app`, подписанный Developer ID (`export_method: developer-id`) |
| `mac make_dmg` | Собирает `.dmg` из `.app` (симлинк `/Applications`, подпись `.dmg` через `codesign`) |
| `mac notarize_dmg` | Отправляет `.dmg` на нотаризацию (`notarize`/`notarytool`) и делает `staple` |
| `mac generate_appcast_feed` | Генерирует `appcast.xml` (Sparkle, только если задан `SPARKLE_PRIVATE_KEY`) и `latest.json` (всегда) |
| `mac release_direct` | Полный цикл: `build_direct` → `make_dmg` → `notarize_dmg` → `generate_appcast_feed` |

Переменные окружения — общие с `Fastfile_macos`, плюс:

| Переменная | Значение по умолчанию | Назначение |
|---|---|---|
| `DMG_NAME` | значение `MAIN_TARGET` | Имя тома и файла `.dmg` |
| `SPARKLE_PRIVATE_KEY` | — | Приватный ed25519-ключ Sparkle (содержимое файла), включает генерацию `appcast.xml` |
| `SPARKLE_DOWNLOAD_URL_PREFIX` | — | Публичный префикс URL, где будет опубликован `.dmg` (используется в appcast/`latest.json`) |
| `SPARKLE_TOOLS_VERSION` | `2.6.4` | Версия Sparkle tools для скачивания `generate_appcast`, если бинарь не найден локально |
| `DIRECT_SIGNING_STYLE` | `automatic` | `signingStyle` для сборки `.app` |
| `MACOS_MATCH_DIRECT_BRANCH` | `macos_developer_id` | Ветка match-репозитория с Developer ID сертификатами |
| `DEVELOPER_ID_APPLICATION_IDENTITY` | автоопределение из keychain | Имя сертификата "Developer ID Application" для подписи `.dmg` |

### 🧰 Общие

| Lane | Что делает |
|---|---|
| `clear_keychain` | Сбрасывает системный default keychain и удаляет временный keychain fastlane |
| `register_new_device` | Интерактивно регистрирует новое устройство и перегенерирует dev-профили |

## 🤖 Пример CI (GitLab CI)

```yaml
stages:
  - build
  - upload_dsyms
  - upload_testflight

variables:
  APP_IDENTIFIER: "com.company.appname"
  MAIN_TARGET: "AppName"
  APP_VERSION: "1.2.3"
  APPSTORE_KEY_ID: "${APPSTORE_KEY_ID}"
  APPSTORE_ISSUER_ID: "${APPSTORE_ISSUER_ID}"
  APPSTORE_KEY_CONTENT: "${APPSTORE_KEY_CONTENT}"
  MATCH_PASSWORD: "${MATCH_PASSWORD}"
  MATCH_GIT_URL: "${MATCH_GIT_URL}"

build:
  stage: build
  tags: [macos]
  script:
    - bundle install
    - bundle exec fastlane build
  artifacts:
    paths:
      - fastlane/artifacts/*.ipa
      - fastlane/artifacts/*.dSYM.zip
    expire_in: 1 hour

upload_dsyms:
  stage: upload_dsyms
  tags: [macos]
  needs: [build]
  script:
    - bundle install
    - bundle exec fastlane upload_dsyms firebase:true

upload_testflight:
  stage: upload_testflight
  tags: [macos]
  needs: [upload_dsyms]
  script:
    - bundle install
    - bundle exec fastlane upload_testflight
```

Уведомления о статусе пайплайна (Telegram и т.д.) не входят в зону
ответственности этого репозитория — подключаются отдельно через relay-шаблоны
gitlab-ci/Messenger в CI-конфиге проекта-потребителя.

## 🔄 Обновление версий

- Пинуйте `import_from_git` на конкретный тег (`branch: 'v3.1.0'`), а не на
  `main` — так обновления `fastlane-tools` не ломают ваш пайплайн незаметно.
- Перед обновлением смотрите [CHANGELOG.md](./CHANGELOG.md): там перечислены
  breaking changes, исправления и новые возможности каждой версии.
- Обновление — это смена значения `branch:` (или `version:`) на новый тег в
  `fastlane/Fastfile` вашего проекта и последующий прогон `fastlane lanes`
  для проверки, что импорт и зависимости резолвятся.
- Проект придерживается обратной совместимости в рамках мажорной версии:
  существующие ENV-переменные и сигнатуры lane-ов не удаляются и не меняют
  поведение без мажорного релиза.

## 📚 Документация и требования

- [docs/USAGE_GUIDE.md](./docs/USAGE_GUIDE.md) — детальное описание всех
  lane-ов, workflow-примеры (новая сборка, external testers, публикация в App
  Store, добавление устройства), troubleshooting, best practices.
- [CHANGELOG.md](./CHANGELOG.md) — история изменений по версиям.

**Требования:** Xcode (установлен и настроен), Ruby ≥ 2.7, Bundler, Fastlane
(ставится через Bundler по `Gemfile`).

**Назначение:** внутренний инструмент ESKARIA для унификации CI/CD пайплайнов
iOS/macOS-проектов.

**Полезные ссылки:** [Fastlane docs](https://docs.fastlane.tools) ·
[Match](https://docs.fastlane.tools/actions/match/) ·
[TestFlight](https://developer.apple.com/testflight/) ·
[App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)

---

**Версия:** 3.1.0
**Последнее обновление:** 02.07.2026
