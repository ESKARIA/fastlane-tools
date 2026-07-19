# Changelog

Все значимые изменения этого проекта документируются в этом файле.

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.0.0/),
проект придерживается [Semantic Versioning](https://semver.org/lang/ru/).

## [Unreleased]

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
