# 🚀 Fastlane Tools

Набор модульных инструментов для автоматизации процессов разработки и публикации iOS приложений с помощью Fastlane.

## 📋 Описание

Этот репозиторий содержит готовые к использованию Fastfile модули для:

- ✅ Управления сертификатами и provisioning profiles через `match`
- ✅ Сборки IPA файлов для App Store
- ✅ Загрузки сборок в TestFlight (internal и external testers)
- ✅ Публикации приложений в App Store
- ✅ Загрузки символов (dSYM) в AppMetrica и Firebase Crashlytics
- ✅ Telegram уведомлений о статусе сборок
- ✅ Сбора метрик выполнения lanes

## 🚀 Быстрый старт

### 1. Установка

```bash
# Клонируйте репозиторий или используйте import_from_git
git clone git@github.com:ESKARIA/fastlane-tools.git

# Установите зависимости
bundle install
```

### 2. Настройка переменных окружения

```bash
export APP_IDENTIFIER="com.company.appname"
export MAIN_TARGET="AppName"
export APP_VERSION="1.2.3"
export CI_PIPELINE_IID="123"
export APPSTORE_KEY_ID="ABC123XYZ"
export APPSTORE_ISSUER_ID="12345678-1234-1234-1234-123456789012"
export APPSTORE_KEY_CONTENT="$(cat key.p8 | base64)"
```

### 3. Первая сборка

```bash
# Генерация сертификатов
fastlane match_generate_appstore

# Сборка приложения
fastlane build

# Загрузка в TestFlight
fastlane upload_testflight
```

## 📖 Основные команды

### Управление сертификатами

```bash
# Генерация App Store сертификатов
fastlane match_generate_appstore

# Установка сертификатов
fastlane match_install_appstore
```

### Сборка и публикация

```bash
# Сборка IPA файла
fastlane build

# Загрузка в TestFlight для internal testers
fastlane upload_testflight

# Загрузка в TestFlight для external testers
fastlane upload_external_testflight groups:"External Public Beta"

# Отправка на рецензирование в App Store
fastlane pass_to_review
```

### Дополнительные команды

```bash
# Загрузка символов (dSYM)
fastlane upload_dsyms firebase:true

# Запуск тестов
fastlane tests scheme:"AppName" device:"iPhone 13"

# Создание git тега
fastlane tagging tags:true
```

## 📚 Документация

Полная документация находится в папке [`docs/`](./docs/):

- **[Полное руководство](./docs/USAGE_GUIDE.md)** - детальное описание всех lanes, workflow примеры, troubleshooting
- **[Навигация по документации](./docs/README.md)** - структура документации

### Быстрые ссылки

- 🚀 [Быстрый старт](./docs/USAGE_GUIDE.md#быстрый-старт)
- 📖 [Описание всех lanes](./docs/USAGE_GUIDE.md#основные-lanes)
- 🔄 [Примеры workflow](./docs/USAGE_GUIDE.md#workflow-примеры)
- 🔐 [Переменные окружения](./docs/USAGE_GUIDE.md#переменные-окружения)
- 🐛 [Troubleshooting](./docs/USAGE_GUIDE.md#troubleshooting)

## ⚙️ Особенности

### Поддержка множественных bundle identifiers

Система поддерживает несколько bundle identifiers через запятую:

```bash
export APP_IDENTIFIER="com.app.main,com.app.widget,com.app.watchkit"
fastlane build  # Автоматически обработает все identifiers
```

### Автоматическое определение типа загрузки

```bash
# Автоматически загружает для external testers, если установлена переменная
export EXTERNAL_TESTFLIGHT_GROUPS="External Public Beta"
fastlane upload_testflight  # Автоматически для external testers
```

### Telegram уведомления

Настройте уведомления для получения информации о статусе сборок:

```bash
export TELEGRAM_ENABLED="true"
export TELEGRAM_BOT_TOKEN="your_bot_token"
export TELEGRAM_CHAT_ID="your_chat_id"
```

### Retry логика

Автоматическая retry логика для сетевых операций (до 3 попыток с экспоненциальной задержкой).

## 📁 Структура проекта

```
fastlane-tools/
├── fastlane/
│   ├── Fastfile                 # Главный файл конфигурации
│   ├── Fastfile_match          # Управление сертификатами
│   ├── Fastfile_build          # Сборка приложений
│   ├── Fastfile_upload         # Загрузка в TestFlight
│   ├── Fastfile_appstore       # Работа с App Store
│   ├── Fastfile_dsyms         # Загрузка символов
│   ├── Fastfile_tests         # Запуск тестов
│   ├── Fastfile_create_app    # Создание приложения
│   └── Fastfile_helpers       # Вспомогательные функции
├── docs/                        # Документация
│   ├── README.md               # Навигация по документации
│   └── USAGE_GUIDE.md          # Полное руководство
└── README.md                   # Этот файл
```

## 🔧 Требования

- **Xcode** - установлен и настроен
- **Ruby** - версия 2.7 или выше
- **Bundler** - для управления зависимостями
- **Fastlane** - установлен через Bundler

## 🤝 Использование в проектах

### Через import_from_git

Добавьте в ваш `fastlane/Fastfile`:

```ruby
import_from_git(
  url: 'git@github.com:ESKARIA/fastlane-tools.git',
  path: 'fastlane/Fastfile_match',
  dependencies: [
    'fastlane/Fastfile_build',
    'fastlane/Fastfile_upload',
    'fastlane/Fastfile_appstore',
    'fastlane/Fastfile_helpers'
  ]
)
```

## 📝 Лицензия

Этот проект предназначен для внутреннего использования ESKARIA.

## 🔗 Полезные ссылки

- [Fastlane документация](https://docs.fastlane.tools)
- [Match документация](https://docs.fastlane.tools/actions/match/)
- [TestFlight документация](https://developer.apple.com/testflight/)
- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)

---

**Версия:** 2.0  
**Последнее обновление:** 2024
