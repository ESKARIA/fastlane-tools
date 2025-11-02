# 🔧 Настройка CI/CD для автоматической загрузки в External Testers

## Проблема

Вы добавили переменную `EXTERNAL_TESTFLIGHT_GROUPS`, но CI/CD все равно не отправляет сборку в группы external testers автоматически.

## Решение

Теперь lane `upload_testflight` **автоматически определяет** тип загрузки на основе переменной окружения `EXTERNAL_TESTFLIGHT_GROUPS`.

## Как это работает

### Автоматическое определение типа загрузки

Lane `upload_testflight` теперь автоматически проверяет:

1. **Если установлена переменная `EXTERNAL_TESTFLIGHT_GROUPS`** → загружает для **External Testers**
2. **Если переменная не установлена** → загружает для **Internal Testers**

## Настройка CI/CD

### Вариант 1: GitLab CI (.gitlab-ci.yml)

```yaml
deploy_testflight_external:
  stage: deploy
  script:
    - bundle install
    - |
      export APP_VERSION="${CI_COMMIT_TAG:-$(cat VERSION)}"
      export CI_PIPELINE_IID="${CI_PIPELINE_ID}"
      export APP_IDENTIFIER="com.company.appname"
      export MAIN_TARGET="AppName"
      export APPSTORE_KEY_ID="${APPSTORE_KEY_ID}"
      export APPSTORE_ISSUER_ID="${APPSTORE_ISSUER_ID}"
      export APPSTORE_KEY_CONTENT="${APPSTORE_KEY_CONTENT}"
      # Ключевая переменная для автоматического определения external testers
      export EXTERNAL_TESTFLIGHT_GROUPS="External Public Beta"
      # Сборка приложения
      bundle exec fastlane build
      # Загрузка в TestFlight (автоматически определит external по переменной)
      bundle exec fastlane upload_testflight
  only:
    - tags
    - main
```

### Вариант 2: GitHub Actions (.github/workflows/deploy.yml)

```yaml
name: Deploy to TestFlight

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:

jobs:
  deploy:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      
      - name: Build and Upload
        env:
          APP_VERSION: ${{ github.ref_name }}
          BUILD_NUMBER: ${{ github.run_number }}
          APP_IDENTIFIER: com.company.appname
          MAIN_TARGET: AppName
          APPSTORE_KEY_ID: ${{ secrets.APPSTORE_KEY_ID }}
          APPSTORE_ISSUER_ID: ${{ secrets.APPSTORE_ISSUER_ID }}
          APPSTORE_KEY_CONTENT: ${{ secrets.APPSTORE_KEY_CONTENT }}
          # Ключевая переменная для автоматического определения external testers
          EXTERNAL_TESTFLIGHT_GROUPS: "External Public Beta"
        run: |
          bundle exec fastlane build
          bundle exec fastlane upload_testflight
```

### Вариант 3: Jenkins (Jenkinsfile)

```groovy
pipeline {
    agent any
    
    environment {
        APP_IDENTIFIER = 'com.company.appname'
        MAIN_TARGET = 'AppName'
        // Ключевая переменная для автоматического определения external testers
        EXTERNAL_TESTFLIGHT_GROUPS = 'External Public Beta'
    }
    
    stages {
        stage('Build') {
            steps {
                sh 'bundle install'
                sh 'bundle exec fastlane build'
            }
        }
        
        stage('Upload to TestFlight') {
            steps {
                // Автоматически определит external testers по переменной
                sh 'bundle exec fastlane upload_testflight'
            }
        }
    }
}
```

## Использование в разных сценариях

### Сценарий 1: Всегда Internal Testers

Не устанавливайте переменную `EXTERNAL_TESTFLIGHT_GROUPS`:

```bash
# CI/CD будет загружать для internal testers
fastlane upload_testflight
```

### Сценарий 2: Всегда External Testers

Установите переменную `EXTERNAL_TESTFLIGHT_GROUPS`:

```bash
export EXTERNAL_TESTFLIGHT_GROUPS="External Public Beta"
fastlane upload_testflight
```

### Сценарий 3: Условная загрузка (по ветке)

В GitLab CI можно использовать условия:

```yaml
deploy_internal:
  script:
    - bundle exec fastlane build
    # НЕ устанавливаем EXTERNAL_TESTFLIGHT_GROUPS → internal testers
    - bundle exec fastlane upload_testflight
  only:
    - develop

deploy_external:
  script:
    - bundle exec fastlane build
    - export EXTERNAL_TESTFLIGHT_GROUPS="External Public Beta"
    # Автоматически определит external по переменной
    - bundle exec fastlane upload_testflight
  only:
    - main
    - tags
```

## Отладка

### Проверка, что переменная установлена

Добавьте в CI/CD скрипт перед загрузкой:

```bash
echo "EXTERNAL_TESTFLIGHT_GROUPS: ${EXTERNAL_TESTFLIGHT_GROUPS}"
echo "Будет загружено для: $([ -n "$EXTERNAL_TESTFLIGHT_GROUPS" ] && echo "External Testers" || echo "Internal Testers")"
```

### Логи fastlane

Используйте verbose режим для детальной информации:

```bash
fastlane upload_testflight --verbose
```

В логах вы увидите:
```
[Header] Загрузка в TestFlight (External Testers) - автоопределение
[Message] Группы: External Public Beta
```

или

```
[Header] Загрузка в TestFlight (Internal Testers)
```

## Дополнительные параметры

Если нужно явно указать тип загрузки, можно использовать параметр:

```bash
# Принудительно для external testers
fastlane upload_testflight external:true groups:"External Public Beta"

# Принудительно для internal testers
fastlane upload_testflight external:false
```

## Важные замечания

1. **Переменная должна быть установлена ДО вызова `upload_testflight`**
   ```bash
   # ✅ Правильно
   export EXTERNAL_TESTFLIGHT_GROUPS="External Public Beta"
   fastlane upload_testflight
   
   # ❌ Неправильно (переменная не будет видна)
   fastlane upload_testflight
   export EXTERNAL_TESTFLIGHT_GROUPS="External Public Beta"
   ```

2. **Группы должны существовать в App Store Connect**
   - Создайте группы заранее в App Store Connect
   - Названия групп должны точно совпадать (учитывается регистр)

3. **Первая сборка версии для external testers требует рецензирования**
   - Время ожидания: 24-48 часов
   - Changelog обязателен

## Проверка результата

После запуска CI/CD проверьте логи. Вы должны увидеть одно из:

### Для External Testers:
```
[Header] Загрузка в TestFlight (External Testers) - автоопределение
[Message] Группы: External Public Beta
[Success] ✅ Сборка успешно загружена для external testers в группы: External Public Beta
```

### Для Internal Testers:
```
[Header] Загрузка в TestFlight (Internal Testers)
[Success] ✅ Загрузка завершена успешно (Internal Testers)
```

---

**Готово!** Теперь при установке переменной `EXTERNAL_TESTFLIGHT_GROUPS` в CI/CD, сборка автоматически будет загружаться для external testers.

