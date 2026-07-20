# Changelog

Все значимые изменения этого проекта документируются в этом файле.

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.0.0/),
проект придерживается [Semantic Versioning](https://semver.org/lang/ru/).

## [4.0.0] - 2026-07-21

### Removed

- **BREAKING:** вся Ruby-логика Telegram-уведомлений полностью удалена из
  `fastlane-tools`. Ответственность за уведомления о статусе pipeline
  (сборка/загрузка/ошибки) целиком перенесена в relay-шаблоны
  gitlab-ci/Messenger — переход проверен там end-to-end.
  - `Fastfile_helpers`: удалены прямой и relay-режим отправки — функции
    `send_telegram_notification`, `format_telegram_message`,
    `notify_telegram_start`, `notify_telegram_stage`, `notify_telegram_success`,
    `notify_telegram_error`, `send_final_telegram_message`,
    `edit_telegram_message`, `update_telegram_progress`,
    `get_progress_message_id`, `save_progress_message_id`,
    `get_pipeline_stages`, `get_current_stage_name`,
    `format_stages_progress`, `create_telegram_progress_message_via_relay`,
    `create_telegram_progress_message_direct`, `telegram_relay_enabled?`,
    `telegram_relay_request`, `telegram_relay_wait_for_status`,
    `telegram_relay_send_message`, `telegram_relay_edit_message`,
    `sanitize_secrets`, `escape_html` и константы
    `PROGRESS_MESSAGE_ID_FILE`/`PROGRESS_STAGES_DETAILS_FILE`/
    `PROGRESS_COMPLETED_STAGES_FILE`. `get_pipeline_url` сохранён (используется
    метриками, Telegram-специфичным не был).
  - `FastlaneMetrics`: удалены `to_telegram_message` и
    `format_metrics_for_telegram`; `finish_metrics` больше не принимает
    параметр `send_to_telegram` (сигнатура: `finish_metrics(save_to_file:
    true)`).
  - Все вызовы `notify_telegram_*`/`send_final_telegram_message` убраны из
    `Fastfile` (`before_all`/`after_all`/`error`), `Fastfile_build`,
    `Fastfile_upload`, `Fastfile_dsyms`, `Fastfile_macos` — build/upload/
    tagging-логика не затронута.
  - Убрана зависимость `gem 'fastlane-plugin-telegram'` из `Pluginfile` (в
    коде не использовалась — уведомления шли через прямые HTTP-вызовы).
  - Удалены `spec/telegram_formatting_spec.rb`, `spec/telegram_relay_spec.rb`,
    `spec/sanitize_secrets_spec.rb` (был целиком про `sanitize_secrets`,
    других сценариев не покрывал), `docs/TELEGRAM_NOTIFICATIONS_EXAMPLES.md`.
  - `README.md`/`docs/README.md`/`docs/USAGE_GUIDE.md`: убраны все разделы,
    таблицы переменных и примеры, описывающие Telegram-уведомления;
    `.gitignore` больше не содержит `fastlane/.telegram_*` файлов.
  - ENV-переменные `TELEGRAM_ENABLED`, `TELEGRAM_BOT_TOKEN`,
    `TELEGRAM_CHAT_ID`, `TELEGRAM_PROGRESS_MODE`, `TELEGRAM_PROGRESS_MESSAGE_ID`,
    `TELEGRAM_COMPLETED_STAGES`, `TELEGRAM_USE_RELAY`,
    `TELEGRAM_RELAY_BASE_URL`, `TELEGRAM_RELAY_API_KEY` больше нигде не
    читаются этим репозиторием — нет ни прямой отправки, ни фоллбэка.

## [3.5.0] - 2026-07-20

### Added

- `Fastfile_helpers`: опциональный relay-режим для Telegram-уведомлений —
  `TELEGRAM_USE_RELAY=true` (+ `TELEGRAM_RELAY_BASE_URL`,
  `TELEGRAM_RELAY_API_KEY`) отправляет уведомления через
  [TelegramProxy](https://gitlab.sportplay.tech/sportplay/telegram-bot-relay)
  вместо прямого `api.telegram.org` — не нужно хранить сырой
  `TELEGRAM_BOT_TOKEN` в переменных проекта, ретраи и rate-limit на стороне
  relay. По умолчанию выключено (`TELEGRAM_USE_RELAY` не установлен) —
  поведение не меняется, используется прежний прямой вызов. Если
  `TELEGRAM_USE_RELAY=true`, но relay-переменные не заданы, автоматический
  откат на прямой API с предупреждением в логе, без падения pipeline.
  Новые низкоуровневые функции: `telegram_relay_enabled?`,
  `telegram_relay_request`, `telegram_relay_wait_for_status`,
  `telegram_relay_send_message`, `telegram_relay_edit_message`. Режим
  прогресс-сообщения (`TELEGRAM_PROGRESS_MODE`) поддержан в обоих режимах —
  `send_telegram_notification`, `edit_telegram_message` и создание нового
  прогресс-сообщения в `update_telegram_progress` (вынесено в
  `create_telegram_progress_message_via_relay`/`_direct`) сами выбирают путь
  по `telegram_relay_enabled?`. Relay асинхронный, поэтому перед
  `editMessageText` код дожидается статуса `delivered` (до 15 секунд), чтобы
  узнать настоящий Telegram `message_id`. Покрыто RSpec
  (`spec/telegram_relay_spec.rb`), задокументировано в `README.md` и
  `TELEGRAM_NOTIFICATIONS.md`.

## [3.4.0] - 2026-07-20

### Added

- `Fastfile_helpers`: `multiplatform_scheme?(options)` — чистая функция,
  включает опциональный режим для Xcode-таргетов, собирающих несколько
  платформ из одного target/scheme (например iOS+macOS одновременно).
  Включается через lane-опцию `multiplatform: true` или
  `ENV['MULTIPLATFORM_SCHEME'] == 'true'`; по умолчанию выключен, не
  затрагивает обычные однoplatform-проекты. Покрыто RSpec
  (`spec/multiplatform_scheme_spec.rb`).
- `lane :build` (iOS, `Fastfile_build`) и `lane :build` (macOS,
  `Fastfile_macos`): в мультиплатформенном режиме версия/build number
  передаются ТОЛЬКО через `xcargs` (`MARKETING_VERSION=`/
  `CURRENT_PROJECT_VERSION=`), прямая запись в pbxproj
  (`set_version_for_target`/`sync_build_number_for_other_targets`)
  пропускается — на мультиплатформенном таргете (`iphoneos`+`macosx` в одном
  target) такая запись ломает `xcodebuild -exportArchive`:
  `IDEDistributionMethodManager ... Unknown Distribution Error` /
  `exportOptionsPlist error for key 'method' expected one {} but found
  <method>`. Архивация при этом проходит успешно — падает именно экспорт, и
  падает независимо от содержимого `exportOptions.plist` (auth key, teamID,
  installer cert — ничего из этого не влияло). Причина на стороне Xcode,
  Apple не документирует; воспроизведено и устранено на реальном проекте
  (Messenger, миграция на fastlane-tools, 2026-07). iOS-сторона lane :build
  дополнительно получила опциональные `sdk:`/`destination:`
  (`options[:sdk]`/`options[:destination]` > `ENV['IOS_SDK']`/
  `ENV['IOS_DESTINATION']`) — тот же паттерн, что уже был у macOS с тикета
  3.3.0. Покрыто структурными RSpec (`spec/multiplatform_build_spec.rb`).
- `Fastfile_macos`: `mac_app_identifiers` теперь читает опциональный
  `ENV['MAC_APP_IDENTIFIER']` (отдельный, более узкий CSV-список bundle id
  специально для macOS), приоритетнее общего `APP_IDENTIFIER`. Нужно для
  проектов с iOS-only расширениями (Widget/Live Activity/Notification
  Service), у которых физически нет и не должно быть macOS-профиля — без
  этой опции `mac_install_match` падал `No matching provisioning profiles
  found ... readonly` на таком identifier.

### Fixed

- `Fastfile_macos`, `lane :build`: имя provisioning-профиля в
  `export_options.provisioningProfiles` собиралось без суффикса `" macos"`
  (`"match AppStore <id>"` вместо `"match AppStore <id> macos"`) — match
  хранит macOS AppStore-профиль под ИМЕНЕМ с этим суффиксом (без него это
  имя iOS-профиля того же bundle id). gym подставлял iOS-профиль в
  exportOptions.plist, `xcodebuild -exportArchive` падал: `Provisioning
  profile "match AppStore <id>" has platforms "visionOS, watchOS, and
  iOS", which does not match the current platform "macOS"`. Архивация при
  этом проходила успешно (сертификат/keychain были корректны) — падал
  только export.
- `Fastfile_macos`, `lane :build`: `output_name:` для `build_app` передавал
  `mac_pkg_file_name` (уже включает `.pkg`) — gym сам добавляет расширение
  по типу экспорта, получалось `<name>.pkg.pkg`. Экспорт формально
  проходил успешно, но последующая валидация артефакта (искала файл с
  одним `.pkg`) не находила его.
- `Fastfile_macos`: `mac_pkg_folder_path` клал `.pkg` в подпапку
  `ARTIFACTS_PATH/pkg/` — нарушало собственную задокументированную
  конвенцию репозитория (см. комментарий в главном `Fastfile`: "Плоский
  layout обязателен: shared-gitlab-ci основных проектов собирает
  артефакты плоским глобом"). Общий CI-темплейт с плоским глобом
  `fastlane/artifacts/*.pkg` не подхватывал файл из подпапки — между
  джобой сборки и джобой заливки в TestFlight (разные CI-процессы)
  артефакт не передавался: "Не найден .pkg для загрузки" при полностью
  успешной сборке. Теперь `mac_pkg_folder_path` == `ARTIFACTS_PATH`,
  плоско, как у iOS (`IPA_FOLDER_PATH`/`DSYM_FOLDER_PATH`).

Все четыре находки (профиль без суффикса, двойное расширение, вложенная
папка pkg/, отсутствие MAC_APP_IDENTIFIER) обнаружены на живом смок-тесте
миграции Messenger — `Fastfile_macos` из тикета 3.3.0 никогда не проходил
реальный CI-прогон iOS+macOS split-job пайплайна до этого момента.

## [3.3.0] - 2026-07-19

### Changed

- `Fastfile_macos`: генерация и установка `mac_installer_distribution`
  сертификата (`mac_generate_match`/`mac_install_match`, `installer: true`)
  разбиты на два отдельных вызова `match` вместо одного вызова с
  `additional_cert_types`. Второй вызов идёт с `skip_provisioning_profiles: true`
  (у installer-сертификата нет собственного provisioning-профиля). Обходит
  fastlane/fastlane#21447 (`sigh` при двух типах сертификата в одном вызове
  `match` может выбрать «первую попавшуюся» identity и привязать профиль не к
  тому сертификату) и учитывает fastlane/fastlane#21189.
- `lane :build` (macOS) — `sdk`/`destination` теперь настраиваемые:
  `options[:sdk]`/`options[:destination]` > `ENV['MAC_SDK']`/`ENV['MAC_DESTINATION']` >
  дефолт `'macosx'`/`'generic/platform=macOS'` (прежнее неявное поведение).
  Нужно для мультиплатформенных схем (одна схема собирает и `iphoneos`, и
  `macosx`), где implicit-выбор SDK/destination может забрать не тот артефакт.

### Added

- `Fastfile_macos`: регистрация текущего Mac как provisioning-устройства
  (`mac_this_device_udid`, `mac_register_this_device`) — macOS
  development-профиль требует зарегистрированных устройств, иначе App Store
  Connect API отклоняет создание профиля. Идемпотентно, не валит lane, если
  UDID не удалось определить. Подключено в `match_generate_dev` (перед
  генерацией профиля); НЕ подключено в readonly `match_install_dev` и в
  appstore/build lane.
- `Fastfile_helpers`: чистые функции `parse_provisioning_udid` (извлекает
  Provisioning UDID из вывода `system_profiler SPHardwareDataType`) и
  `mac_device_display_name` (имя компьютера или фоллбэк `"Mac <UDID суффикс>"`),
  покрыты RSpec (`spec/mac_device_registration_spec.rb`).
- `spec/fastfile_macos_spec.rb` — структурные тесты `Fastfile_macos` (состав
  9 lane, синтаксическая валидность, двухшаговый `match` для installer-
  сертификата, подключение `register_devices`, конфигурация `sdk`/`destination`
  в `build`), по образцу `spec/fastfile_macos_direct_spec.rb`.

## [3.2.0] - 2026-07-10

### Added

- Новый модуль `Fastfile_macos_direct` — прямая (Developer ID) дистрибуция
  macOS-приложений в обход App Store: подпись Developer ID, сборка `.dmg`,
  нотаризация через `notarize`/`notarytool`, генерация Sparkle-фида
  (`appcast.xml`) и `latest.json` для автообновлений.
- 7 новых lane в `platform :mac`: `match_generate_developer_id`,
  `match_install_developer_id`, `build_direct`, `make_dmg`, `notarize_dmg`,
  `generate_appcast_feed`, `release_direct`.
- Новые переменные окружения модуля: `DMG_NAME`, `SPARKLE_PRIVATE_KEY`,
  `SPARKLE_DOWNLOAD_URL_PREFIX`, `SPARKLE_TOOLS_VERSION`,
  `DIRECT_SIGNING_STYLE`, `MACOS_MATCH_DIRECT_BRANCH`,
  `DEVELOPER_ID_APPLICATION_IDENTITY`.

## [3.1.0] - 2026-07-02

### Security

- Экранирование `HELPER_PATH` через `shellescape` перед вызовом `chmod` в `Fastfile_dsyms`.
- Маскировка секретов в Telegram-уведомлениях.
- Скрытие значения `APPMETRICA_KEY` из логов (`log: false`).

### Fixed

- Сравнение версий приложения через `Gem::Version` вместо строкового сравнения (`fix(appstore)`).
- Успешная загрузка со статусом «already submitted» больше не считается ошибкой.
- Regex обновления года в метаданных сужен до `19xx`/`20xx`, чтобы не задевать посторонние числа.
- Путь к `metrics.json` привязан к каталогу `Fastfile_helpers`.
- `Pluginfile` возвращён в индекс git, `metrics.json` больше не хранится в индексе.

### Changed

- CI-workflow включён и обновлён: bundler-cache, syntax-check, rubocop, `bundle exec rspec`, bundler-audit, push в `main`.

### Refactored

- Общая retry/«уже выполнено»-логика загрузки в TestFlight вынесена в `Fastfile_helpers` (`upload_with_testflight_retry`, `NON_RETRYABLE_TESTFLIGHT_ERRORS`).

### Tests

- Добавлены RSpec-тесты (33 теста) для чистой Ruby-логики `Fastfile_helpers`.

## [3.0.0] - 2026-01-27

Согласно истории изменений в README.md: добавлена поддержка Telegram-уведомлений
о статусе сборок, включая режим прогресс-сообщений, и другие улучшения
предыдущих версий. Подробности см. в README.md.
