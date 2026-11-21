# Flieger 965

Аналоговий циферблат Garmin Connect IQ для Forerunner 965. В активному режимі показує місцевий час, день тижня й число, заряд батареї та точне значення хвилин. У режимі Always-On видно лише стрілки та годинні мітки.

## Структура проєкту

- `manifest.xml` задає ідентифікатор застосунку, тип циферблата та модель `fr965`.
- `monkey.jungle` задає конфігурацію збірки.
- `source/Flieger.mc` містить логіку, розташування елементів, кольори та режим Always-On.
- `resources/` містить іконку, описи ресурсів і растрові шрифти. Для зміни гарнітури замініть відповідну пару `.fnt` і `.png` та збережіть посилання на неї в `resources/resources.xml`. Ліцензія шрифтів міститься в `FONT-LICENSE.txt`.

## Збірка та встановлення

1. Установіть [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) і завантажте профіль **Forerunner 965** у SDK Manager. Проєкт збирався з Connect IQ SDK 9.3.0.
2. У VS Code встановіть розширення **Monkey C** від Garmin і відкрийте кореневу папку проєкту. У палітрі команд виберіть **Monkey C: Generate Developer Key** і збережіть приватний ключ поза репозиторієм. Для наступних збірок використовуйте той самий ключ і зберігайте його резервну копію.
3. Виконайте **Monkey C: Build for Device** та виберіть **Forerunner 965**. Або виконайте з кореня проєкту, якщо `monkeyc` доступний у `PATH`:

   ```sh
   mkdir -p bin
   monkeyc -f monkey.jungle -d fr965 -o bin/FLIEGER.PRG -y /path/to/developer_key.der -l 3 -w -r
   ```

4. Для перевірки відкрийте Connect IQ Simulator і виконайте `monkeydo bin/FLIEGER.PRG fr965`. Перевірте активний режим і Always-On.
5. Під’єднайте годинник через USB і скопіюйте `FLIEGER.PRG` до `GARMIN/APPS`. На годиннику виберіть **Flieger 965** у меню циферблатів. [Інструкція Garmin](https://developer.garmin.com/connect-iq/connect-iq-basics/your-first-app/).

Для оновлень зберігайте ідентифікатор у `manifest.xml`. Якщо перехід із попередньої збірки, підписаної іншим ключем, не спрацює, видаліть попередню копію циферблата з годинника й установіть нову.
