# 📚 Руководство по использованию Fastlane Tools

## 📋 Содержание

1. [Введение](#введение)
2. [Быстрый старт](#быстрый-старт)
3. [Установка и настройка](#установка-и-настройка)
4. [Основные lanes](#основные-lanes)
5. [Workflow примеры](#workflow-примеры)
6. [Переменные окружения](#переменные-окружения)
7. [Дополнительные функции](#дополнительные-функции)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)

---

## 🎯 Введение

Этот репозиторий содержит набор модульных инструментов для автоматизации процессов разработки и публикации iOS приложений с помощью Fastlane. Все Fastfile разделены на логические модули для удобства поддержки и повторного использования.

### Основные возможности:

- ✅ **Управление сертификатами** - автоматическое управление сертификатами и профилями через `match`
- ✅ **Сборка приложений** - автоматическая сборка IPA файлов для App Store
- ✅ **Тестирование** - запуск unit и UI тестов
- ✅ **Загрузка в TestFlight** - автоматическая загрузка сборок в TestFlight (internal и external testers)
- ✅ **Публикация в App Store** - отправка приложений на рецензирование
- ✅ **Управление версиями** - автоматическое управление версиями и build numbers
- ✅ **Загрузка символов** - автоматическая загрузка dSYM в AppMetrica и Firebase Crashlytics
- ✅ **Метрики** - сбор метрик выполнения lanes

---

## 🚀 Быстрый старт

### Минимальный пример: Сборка и загрузка в TestFlight

```bash
# 1. Установите переменные окружения
export APP_IDENTIFIER="com.company.appname"
export MAIN_TARGET="AppName"
export APP_VERSION="1.2.3"
export CI_PIPELINE_IID="123"
export APPSTORE_KEY_ID="ABC123XYZ"
export APPSTORE_ISSUER_ID="12345678-1234-1234-1234-123456789012"
export APPSTORE_KEY_CONTENT="$(cat key.p8 | base64)"

# 2. Соберите приложение
fastlane build

# 3. Загрузите в TestFlight для internal testers
fastlane upload_testflight
```

---

## ⚙️ Установка и настройка

### Предварительные требования

1. **Xcode** - установлен и настроен
2. **Ruby** - версия 2.7 или выше
3. **Bundler** - для управления зависимостями
4. **Fastlane** - установлен через Bundler или system-wide

### Установка

```bash
# 1. Клонируйте репозиторий или используйте import_from_git
git clone git@github.com:ESKARIA/fastlane-tools.git

# 2. Установите зависимости
bundle install
```

### Первоначальная настройка

1. **Создайте App Store Connect API ключ:**
   - Перейдите в [App Store Connect](https://appstoreconnect.apple.com)
   - Откройте Users and Access → Keys
   - Создайте новый API ключ с правами App Manager или Admin
   - Скачайте `.p8` файл и сохраните Key ID и Issuer ID

2. **Настройте переменные окружения:**
   ```bash
   export APP_IDENTIFIER="com.company.appname"
   export MAIN_TARGET="AppName"
   export APPSTORE_KEY_ID="ABC123XYZ"
   export APPSTORE_ISSUER_ID="12345678-1234-1234-1234-123456789012"
   export APPSTORE_KEY_CONTENT="$(cat path/to/key.p8 | base64)"
   ```

3. **Настройте match:**
   ```bash
   # Инициализация match
   fastlane match init
   
   # Первая генерация сертификатов
   fastlane match_generate_appstore
   ```

---

## 📖 Основные lanes

### 🔐 Управление сертификатами

#### `match_generate_appstore`
Генерирует App Store сертификаты и provisioning profiles.

```bash
fastlane match_generate_appstore
```

**Когда использовать:**
- Перед первой сборкой для App Store
- При необходимости обновить сертификаты

#### `match_install_appstore`
Устанавливает App Store сертификаты локально.

```bash
fastlane match_install_appstore
```

**Когда использовать:**
- Перед сборкой для App Store
- При настройке CI/CD

---

### 🏗️ Сборка приложений

#### `build`
Собирает IPA файл для App Store.

```bash
fastlane build
```

**Требует переменные:**
- `APP_VERSION` - версия приложения
- `CI_PIPELINE_IID` или `BUILD_NUMBER` - номер сборки
- `APP_IDENTIFIER` - bundle identifier
- `MAIN_TARGET` - название target

**Результат:**
- IPA и dSYM кладутся плоско в каталог `ARTIFACTS_PATH` (по умолчанию `fastlane/artifacts/`
  в корне проекта, переопределяется через `ENV['ARTIFACTS_PATH']`):
  - IPA файл: `fastlane/artifacts/{TARGET}_v{VERSION}_b{BUILD}.ipa`
  - dSYM файл: `fastlane/artifacts/{TARGET}_v{VERSION}_b{BUILD}.app.dSYM.zip`

**Особенности:**
- Поддержка нескольких bundle identifiers (через запятую)
- Автоматическая валидация артефактов
- Проверка размера IPA файла

---

### 📤 Загрузка в TestFlight

#### `upload_testflight`
Загружает сборку в TestFlight для **internal testers**.

```bash
fastlane upload_testflight
```

**Что делает:**
- Находит IPA файлы в `fastlane/artifacts/`
- Генерирует changelog из git коммитов
- Загружает сборку в TestFlight
- Распределяет для internal testers

**Автоматическое определение типа:**
Если установлена переменная `EXTERNAL_TESTFLIGHT_GROUPS`, автоматически загружает для external testers:

```bash
export EXTERNAL_TESTFLIGHT_GROUPS="External Public Beta"
fastlane upload_testflight  # Автоматически для external testers
```

---

#### `upload_external_testflight`
Загружает сборку в TestFlight для **external testers**.

```bash
# С группой по умолчанию
fastlane upload_external_testflight

# С указанием групп
fastlane upload_external_testflight groups:"External Public Beta,QA Testers"

# Через переменную окружения
EXTERNAL_TESTFLIGHT_GROUPS="External Public Beta" fastlane upload_external_testflight
```

**Важно:**
- Группы должны существовать в App Store Connect
- Первая сборка версии требует рецензирования Apple (24-48 часов)
- Changelog обязателен для external testers

**Retry логика:**
Автоматически повторяет попытки при сетевых ошибках (до 3 попыток с экспоненциальной задержкой).

---

### 📦 Загрузка символов

#### `upload_dsyms`
Загружает dSYM файлы в AppMetrica и/или Firebase.

```bash
# Только AppMetrica
fastlane upload_dsyms

# AppMetrica + Firebase
fastlane upload_dsyms firebase:true
```

**Требует переменные:**
- `APPMETRICA_KEY` - ключ API AppMetrica
- `APPMETRICA_HELPER_PATH` - путь к helper скрипту

---

### 🏪 Работа с App Store

#### `pass_to_review`
Отправляет приложение на рецензирование в App Store.

```bash
fastlane pass_to_review
```

**Что делает:**
1. Находит последнюю сборку в TestFlight
2. Заполняет информацию о compliance
3. Отправляет на рецензирование
4. Объединяет release ветку в main

---

### 🧪 Тестирование

#### `tests`
Запускает unit и UI тесты.

```bash
fastlane tests scheme:"AppName" device:"iPhone 13"
```

**Параметры:**
- `scheme` - схема для тестирования
- `device` - симулятор для тестирования

---

## 🔄 Workflow примеры

### Workflow 1: Новая сборка для Internal Testers

```bash
# 1. Сборка приложения
fastlane build

# 2. (Опционально) Загрузка символов
fastlane upload_dsyms firebase:true

# 3. Загрузка в TestFlight для internal testers
fastlane upload_testflight

# 4. (Опционально) Создание тега
fastlane tagging tags:true
```

---

### Workflow 2: Новая сборка для External Testers

```bash
# 1. Сборка приложения
fastlane build

# 2. Загрузка символов
fastlane upload_dsyms firebase:true

# 3. Загрузка в TestFlight для external testers
fastlane upload_external_testflight groups:"External Public Beta"

# 4. Создание тега
fastlane tagging tags:true
```

**Примечание:** Первая сборка версии потребует рецензирования Apple (24-48 часов).

---

### Workflow 3: Публикация в App Store

```bash
# 1. Автоматическое создание release ветки
fastlane auto_release_branch

# 2. Сборка приложения
fastlane build

# 3. Загрузка в TestFlight
fastlane upload_external_testflight groups:"External Public Beta"

# 4. После тестирования - отправка на рецензирование
fastlane pass_to_review
```

---

### Workflow 4: Добавление нового устройства

```bash
# 1. Регистрация устройства
fastlane register_new_device
# Введите имя и UDID устройства

# 2. Перегенерация development профилей
fastlane match_generate_dev
```

---

## 🔐 Переменные окружения

### Обязательные переменные

```bash
# Идентификатор приложения (можно несколько через запятую)
export APP_IDENTIFIER="com.company.appname"
# или для нескольких targets:
export APP_IDENTIFIER="com.company.appname,com.company.appname.widget"

# Основной target
export MAIN_TARGET="AppName"

# Версия приложения
export APP_VERSION="1.2.3"

# Номер сборки (обычно из CI/CD)
export CI_PIPELINE_IID="123"
# или
export BUILD_NUMBER="123"

# API ключи App Store Connect
export APPSTORE_KEY_ID="ABC123XYZ"
export APPSTORE_ISSUER_ID="12345678-1234-1234-1234-123456789012"
export APPSTORE_KEY_CONTENT="$(cat key.p8 | base64)"
```

### Опциональные переменные

```bash
# Файл проекта (по умолчанию {MAIN_TARGET}.xcodeproj)
export MAIN_PROJECT_FILE="AppName.xcodeproj"

# Пароль для match
export MATCH_PASSWORD="your_match_password"

# Настройки AppMetrica
export APPMETRICA_KEY="your_appmetrica_key"
export APPMETRICA_HELPER_PATH="./helper"

# Загрузка dSYM (по умолчанию включено)
export UPLOAD_DSYMS="true"

# Группы external testers по умолчанию
export EXTERNAL_TESTFLIGHT_GROUPS="External Public Beta"
```

### Настройка для CI/CD

Создайте переменные в вашей CI/CD системе (GitLab CI, GitHub Actions, Jenkins):

```yaml
# GitLab CI пример
variables:
  APP_IDENTIFIER: "com.company.appname"
  MAIN_TARGET: "AppName"
  APP_VERSION: "1.2.3"
  APPSTORE_KEY_ID: "${APPSTORE_KEY_ID}"  # Из CI/CD secrets
  APPSTORE_ISSUER_ID: "${APPSTORE_ISSUER_ID}"
  APPSTORE_KEY_CONTENT: "${APPSTORE_KEY_CONTENT}"
  MATCH_PASSWORD: "${MATCH_PASSWORD}"
```

---

## 🎁 Дополнительные функции

### Метрики и тайминги

Система автоматически собирает метрики выполнения lanes:

- Время начала и завершения
- Длительность выполнения
- Размеры артефактов (IPA, dSYM)
- Статус выполнения
- Количество загруженных файлов

**Где сохраняются:**
- Файл: `fastlane/metrics.json`

**Пример метрик:**
```json
{
  "lane": "build",
  "timestamp": "2024-01-15T10:30:00Z",
  "metrics": {
    "version": "1.2.3",
    "build_number": "123",
    "ipa_size_mb": 45.2,
    "duration_seconds": 180.5,
    "status": "success"
  }
}
```

---

### Retry логика

Автоматическая retry логика для сетевых операций:

- **Максимум попыток:** 3
- **Задержка:** экспоненциальная (5, 10, 20 секунд)
- **Обработка ошибок:** автоматически обрабатывает ошибки "уже выполнено" как успех

**Где используется:**
- Загрузка в TestFlight
- Операции с App Store Connect API

---

## 🐛 Troubleshooting

### Проблема: "Не найдено ни одного IPA файла"

**Решение:**
```bash
# Убедитесь, что вы выполнили сборку
fastlane build

# Проверьте наличие файлов
ls -la fastlane/artifacts/
```

---

### Проблема: "Группа external testers не найдена"

**Решение:**
1. Убедитесь, что группа существует в App Store Connect
2. Проверьте точное название группы (учитывается регистр)
3. Создайте группу вручную, если её нет:
   - App Store Connect → TestFlight → External Testing
   - Нажмите "+" для создания группы

---

### Проблема: "Сертификат не найден"

**Решение:**
```bash
# Установите сертификаты
fastlane match_install_appstore

# Или перегенерируйте их
fastlane match_generate_appstore
```

---

### Проблема: "API ключ недействителен"

**Решение:**
1. Проверьте правильность `APPSTORE_KEY_ID` и `APPSTORE_ISSUER_ID`
2. Убедитесь, что `APPSTORE_KEY_CONTENT` в формате Base64
3. Проверьте права доступа ключа в App Store Connect

---

### Проблема: "Версия уже существует в App Store"

**Решение:**
Используйте новую версию для external testers:
```bash
export APP_VERSION="1.2.4"  # Увеличьте версию
fastlane build
fastlane upload_external_testflight
```

---

### Проблема: "Builds cannot be assigned to this internal group"

**Решение:**
Это нормально, если сборка уже загружена. Система автоматически обрабатывает эту ошибку как успех благодаря retry логике.

---

## ✅ Best Practices

### 1. Управление версиями

- Используйте семантическое версионирование (MAJOR.MINOR.PATCH)
- Инкрементируйте build number для каждой сборки
- Используйте git теги для версий

### 2. Сертификаты

- Всегда используйте `match` для управления сертификатами
- Не коммитьте сертификаты в основной репозиторий
- Храните пароль match в безопасном месте (CI/CD secrets)

### 3. TestFlight

- Используйте internal testers для быстрого тестирования
- Используйте external testers для публичного бета-тестирования
- Всегда указывайте changelog для external testers
- Создавайте группы заранее в App Store Connect

### 4. CI/CD

- Используйте переменные окружения для всех секретов
- Кэшируйте match репозиторий между сборками
- Сохраняйте артефакты (IPA, dSYM) для последующего использования

### 5. Обработка ошибок

- Всегда проверяйте логи при ошибках
- Используйте `--verbose` флаг для детального вывода
- Проверяйте статус сборок в App Store Connect
- Используйте retry логику для сетевых операций

### 6. Множественные bundle identifiers

Если у вас несколько targets (например, основное приложение и widget):

```bash
# Укажите все identifiers через запятую
export APP_IDENTIFIER="com.company.app,com.company.app.widget,com.company.app.watchkit"

# Система автоматически обработает все identifiers
fastlane build
```

---

## 📚 Дополнительные ресурсы

- [Fastlane документация](https://docs.fastlane.tools)
- [Match документация](https://docs.fastlane.tools/actions/match/)
- [TestFlight документация](https://developer.apple.com/testflight/)
- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)

---

## 🤝 Поддержка

Если у вас возникли проблемы или вопросы:

1. Проверьте документацию выше
2. Изучите логи выполнения
3. Проверьте настройки переменных окружения
4. Убедитесь, что все зависимости установлены
5. Используйте `--verbose` флаг для детального вывода

---

**Версия документации:** 3.1.0  
**Последнее обновление:** 02.07.2026
