# Changelog

Все значимые изменения этого проекта документируются в этом файле.

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.0.0/),
проект придерживается [Semantic Versioning](https://semver.org/lang/ru/).

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
