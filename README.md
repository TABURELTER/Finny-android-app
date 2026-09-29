<p align="center">
  <img src="assets/finny/finny_wave_classic.svg" alt="Финни машет лапкой" width="130" style="vertical-align: middle;" />
  <img src="assets/brand/finny_app_icon_512.png" alt="Иконка приложения Финни" width="125" style="border-radius: 28px; box-shadow: 0 8px 24px rgba(0,0,0,0.12); vertical-align: middle; margin: 0 20px;" />
  <img src="assets/finny/finny_wave_classic.svg" alt="Финни машет лапкой" width="130" style="vertical-align: middle;" />
</p>

<h1 align="center">🦊 Питомец Финни</h1>

<p align="center">
  <strong>Игровой мобильный сервис по финансовой грамотности для детей 7–11 лет</strong><br>
  Конкурсное решение для хакатона <strong>«Лидеры цифровой трансформации 2026»</strong> (Депфин Москвы)
</p>

<p align="center">
  <a href="https://github.com/TABURELTER/Finny-android-app"><img src="https://img.shields.io/badge/Хакатон-ЛЦТ_2026-6C38CC?style=flat-square" alt="ЛЦТ 2026" /></a>
  <img src="https://img.shields.io/badge/Платформа-Android_8.0+-3DDC84?style=flat-square&logo=android&logoColor=white" alt="Android" />
  <img src="https://img.shields.io/badge/Стек-Flutter_3_•_Riverpod-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Офлайн-100%25_No_Internet-176B4B?style=flat-square" alt="100% Офлайн" />
  <img src="https://img.shields.io/badge/RuStore-0+_Ready-005FF9?style=flat-square" alt="RuStore" />
</p>

---

## ⚡ Экспресс-проверка для жюри

| Файл / Раздел | Назначение | Ссылка |
|---|---|---|
| 📦 **Готовый APK** | Релизная подписанная сборка (v1.0.0, 58.7 МБ, без IDE) | [📥 finny-pet-release.apk](finny-pet-release.apk) |
| 🎮 **Демо-панель** | Экспресс-тест дней 1–10, сброс и **накрутка монет** | Меню `⋯` ➔ `Демо` |
| 📱 **Скриншоты** | 3 ключевых экрана с физического устройства 360 dp | [docs/screenshots/](docs/screenshots/) |
| 📋 **Матрица ТЗ** | Аудит выполнения всех пунктов ТЗ и Приложения А | [docs/TZ_COMPLIANCE_2026-09-29.md](docs/TZ_COMPLIANCE_2026-09-29.md) |
| 🏷️ **Карточка RuStore** | Черновик публикации: категория «Детские», 0+, описание | [docs/RUSTORE_CARD_DRAFT.md](docs/RUSTORE_CARD_DRAFT.md) |

---

## 📸 Галерея интерфейса

<table align="center">
  <tr>
    <td align="center" width="33%">
      <img src="docs/screenshots/01-create-pet.png" width="220" alt="Создание питомца" /><br>
      <b>1. Создание питомца</b><br>
      <sub>Окрасы, гардероб, и указание имени</sub>
    </td>
    <td align="center" width="33%">
      <img src="docs/screenshots/02-home.png" width="220" alt="Главный экран" /><br>
      <b>2. 3-слойная комната</b><br>
      <sub>Окно с погодой, живой Финни, вещи</sub>
    </td>
    <td align="center" width="33%">
      <img src="docs/screenshots/03-budget-plan.png" width="220" alt="План бюджета" /><br>
      <b>3. План на день</b><br>
      <sub>4 конверта и защита от импульсивных трат</sub>
    </td>
  </tr>
</table>

---

## 🎨 Полная кастомизация Финни

<img src="assets/finny/finny_apricot_happy.svg" width="150" align="right" alt="Финни в берете и куртке" style="margin-left: 15px; margin-bottom: 10px;" />

Ребёнок может настроить Финни **как только пожелает** — от цвета шерстки до деталей гардероба:
- 🦊 **3 базовых окраса:** классический фиолетовый, солнечный абрикос и мятная лагуна.
- 🎨 **Свободный Color Picker:** выбор любого цвета внешности через удобную встроенную палитру.
- 🧢 **Гардероб и аксессуары:** береты, шапочки, куртки и непромокаемый дождевик в ненастную погоду.
- 🐾 **Живые микро-анимации:** моргание, потягивание, мурлыканье и прыжки при касании.

<br clear="right" />

---

## 💡 «Сначала планируй — потом трать» (ТЗ п. 2.5.5)

<img src="assets/finny/finny_smart_glasses.svg" width="145" align="right" alt="Умный Финни в очках" style="margin-left: 15px; margin-bottom: 10px;" />

- 🛡️ **Право на безопасную ошибку:** Финни никогда не погибает. Если денег не хватило — игра объясняет причину и предлагает заработать монеты на мини-работе (*«Ценники»*, *«Заказ»*).
- 🧠 **Умная авто-маршрутизация:** если бюджет на день ещё не закреплён, нажатие на «Лавку», «Задания» или «Мечту» открывает шторку распределения 4 конвертов (*Еда, Запас, Мечта, Радости*).
- ⚡ **Бесшовный переход:** после утверждения плана игра сразу открывает выбранный раздел без повторных кликов.


<br clear="right" />

---

## 🏠 3-слойная комната и динамическая погода

<img src="assets/finny/finny_lagoon_raincoat.svg" width="145" align="right" alt="Финни в дождевике" style="margin-left: 15px; margin-bottom: 10px;" />

- 🌤️ **Слой 1 (Окно с живой погодой):** вид за окном меняется в реальном времени (солнце, дождь, гроза, облака). При ливне Финни советует надеть дождевик!
- 🛋️ **Слой 2 (Интерьер):** векторный уютный домик с прозрачным окном.
- 🧸 **Слой 3 (Инвентарь):** купленные предметы (лежанка, лампа, мяч, робот, змей) гармонично располагаются в комнате.

<br clear="right" />

---

## 🛠️ Демо-режим с накруткой монет (для жюри)

<img src="assets/finny/finny_coin_saver.svg" width="145" align="right" alt="Финни с золотой монеткой" style="margin-left: 15px; margin-bottom: 10px;" />

В меню **`⋯` ➔ `Демо`** экспертам доступны инструменты быстрой проверки:
- ⏩ **Тайм-джамп (дни 1–10):** мгновенный переход к ключевым событиям (дождь, ремонт крыши, ярмарка).
- 🪙 **Накрутка монет:** кнопки `+20 🪙`, `+50 🪙`, `+100 🪙` и `Обнулить` для проверки дорогих покупок и сценариев нехватки средств.
- 🔒 **Изолированный профиль:** тестирование не сбрасывает основной игровой прогресс ребёнка.

<br clear="right" />

---

## 📈 3 стадии взросления питомца

<img src="assets/finny/finny_independent_medal.svg" width="145" align="right" alt="Финни-самостоятельный" style="margin-left: 15px; margin-bottom: 10px;" />

Финни растёт и развивается вместе с финансовой осознанностью ребёнка:
- 🐣 **«Новичок»:** первые шаги, знакомство с конвертами и карманными расходами.
- 🧭 **«Планировщик»:** уверенное распределение бюджета и формирование резерва на случай непредвиденных трат.
- ⭐ **«Самостоятельный»:** достижение большой финансовой цели (мечты), награждение золотой медалью и свободное управление бюджетом.

<br clear="right" />

---

## 🚀 Сборка из исходников

```bash
git clone https://github.com/TABURELTER/Finny-android-app.git
cd Finny-android-app
flutter pub get
flutter build apk --release
```
Файл сборки: `build/app/outputs/flutter-apk/app-release.apk` (и копия в корне `finny-pet-release.apk`).

---

## 📚 Конкурсная документация ([docs/](docs/))

* [📋 Матрица соответствия ТЗ (построчный аудит)](docs/TZ_COMPLIANCE_2026-09-29.md)
* [🏗️ Архитектурная записка](docs/ARCHITECTURE_2026-09-29.md)
* [🎓 Карта образовательного контента](docs/EDUCATIONAL_CONTENT.md)
* [📱 Отчёт о тестировании на S22 Ultra](docs/DEVICE_CHECK_2026-09-29.md)
* [🏷️ Черновик карточки RuStore](docs/RUSTORE_CARD_DRAFT.md)
* [🧪 Матрица ручной приёмки (M01–M15)](docs/MANUAL_ACCEPTANCE_2026-09-29.md)
* [⚖️ Лицензии и авторские права](docs/ASSETS_AND_LICENSES.md)

---
<p align="center">Разработано для финала «Лидеры цифровой трансформации 2026» 💚</p>
