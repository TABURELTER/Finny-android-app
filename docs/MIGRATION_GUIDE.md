# 🚀 Миграция проекта Finny на другую машину

## Быстрый старт (5 минут)

### 1. Клонировать репо
```bash
git clone <repo-url> ~/Finny
cd ~/Finny
```

### 2. Установить Flutter (если ещё нет)
```bash
# macOS
brew install flutter
# или скачай: https://docs.flutter.dev/get-started/install/macos

flutter doctor   # проверь что всё ок
```

### 3. Установить зависимости
```bash
flutter pub get
```

### 4. Восстановить ключ подписи
**Файл `android/app/finny-release.jks` и `android/release-signing.properties` НЕ в репозитории!**

Скопируй их вручную с защищённого носителя:
```bash
# Положи файлы сюда:
# android/app/finny-release.jks
# android/release-signing.properties

# Формат release-signing.properties:
# storeFile=app/finny-release.jks
# keyAlias=finny_release
# storePassword=<password>
# keyPassword=<password>
```

### 5. Запуск
```bash
# Проверка
flutter analyze
flutter test

# Запуск на устройстве
flutter run

# Сборка APK
flutter build apk --release
```

---

## Что НЕ в репозитории (нужно настроить локально)

| Файл/Папка | Описание | Как получить |
|---|---|---|
| `android/app/finny-release.jks` | Ключ подписи APK | Скопировать с USB / облака |
| `android/release-signing.properties` | Пароли от ключа | Скопировать вместе с .jks |
| `.local-android-sdk/` | Android SDK | `flutter doctor` установит |
| `.local-gradle/` | Gradle cache | Создаётся автоматически при сборке |
| `.local-home/` | Локальный HOME для Gradle | Не нужен на macOS |
| `build/` | Артефакты сборки | `flutter build` создаст |
| `*.apk` | Собранные APK | `flutter build apk` создаст |

## Переменные окружения

На **Windows** используются специфичные пути. На macOS они **не нужны** — Flutter/Android Studio сами находят SDK.

Если нужно задать вручную:
```bash
# ~/.zshrc или ~/.bash_profile
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$ANDROID_HOME/platform-tools:$PATH
```

## Структура проекта

```
Finny/
├── lib/               # Dart-код приложения
│   ├── core/          # Тема, токены
│   ├── data/          # Модели, репозитории  
│   ├── features/      # Экраны (11 модулей)
│   ├── game/          # Движок, контент
│   └── shared/        # Общие виджеты
├── assets/            # SVG, изображения
├── fonts/             # Шрифты
├── test/              # Тесты
├── android/           # Android-конфиг
├── windows/           # Windows-конфиг
├── docs/              # Документация
└── pubspec.yaml       # Зависимости
```

## Частые проблемы

### `flutter pub get` падает
```bash
flutter clean
flutter pub get
```

### Android SDK не найден
```bash
flutter doctor --android-licenses
flutter config --android-sdk /path/to/sdk
```

### Ключ подписи не найден при сборке release
Убедись что `android/release-signing.properties` существует и пути в нём правильные.

### Конфликт переводов строк
Уже настроено через `.gitattributes` — все текстовые файлы нормализуются в LF.
