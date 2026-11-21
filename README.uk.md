# Night Flieger

[English](README.md)

Аналоговий циферблат Garmin Connect IQ для Forerunner 965. В активному режимі показує місцевий час, день тижня й число місяця, рівень заряду та точне значення хвилин. У режимі Always-On Display видно стрілки, годинні цифри й мітки.

## Структура проєкту

- `manifest.xml` задає ідентифікатор застосунку, тип циферблата й цільову модель `fr965`.
- `monkey.jungle` задає конфігурацію збірки.
- `source/Flieger.mc` містить логіку відображення, зокрема розташування елементів, кольори й поведінку в режимі Always-On.
- `resources/` містить іконку, описи ресурсів і растрові шрифти. Щоб змінити шрифт, замініть його файли `.fnt` і `.png`. Якщо назви файлів зміняться, оновіть посилання в `resources/resources.xml`. Ліцензія шрифтів міститься у файлі `FONT-LICENSE.txt`.

## Збірка

1. Установіть Garmin Connect IQ SDK і завантажте профіль **Forerunner 965** у SDK Manager. Проєкт збирався з Connect IQ SDK 9.3.0. [Завантажити Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/)
2. Відкрийте папку проєкту у VS Code з установленим розширенням **Monkey C** від Garmin. Якщо потрібен ключ підпису, виконайте **Monkey C: Generate Developer Key** з палітри команд. Зберігайте ключ поза репозиторієм і використовуйте його для наступних оновлень.
3. Виконайте **Monkey C: Build for Device** і виберіть **Forerunner 965**. Якщо `monkeyc` доступний у `PATH`, можна також виконати такі команди з кореня проєкту.

   ```sh
   mkdir -p bin
   monkeyc -f monkey.jungle -d fr965 -o bin/FLIEGER.PRG -y /path/to/developer_key.der -l 3 -w -r
   ```

## Перевірка та встановлення

1. Відкрийте Connect IQ Simulator, виконайте `monkeydo bin/FLIEGER.PRG fr965` і перевірте активний режим та Always-On.
2. Під’єднайте годинник через USB і скопіюйте `FLIEGER.PRG` у папку `GARMIN/APPS`.
3. Від’єднайте годинник і виберіть **Night Flieger** в меню циферблатів. [Інструкція Garmin зі встановлення через USB](https://developer.garmin.com/connect-iq/connect-iq-basics/your-first-app/)

Під час оновлення зберігайте ідентифікатор застосунку в `manifest.xml`. Якщо оновлення, підписане іншим ключем, не встановлюється, видаліть попередню копію з годинника та встановіть нову збірку.
