# Конвертер вложенных JSON-логов в плоскую структуру для импорта в БД PosgreSQL

Скрипт принимает на вход файл с перечнем логов, разбитых символом переноса строки. Строки должны состоять из валидного json'а (см. подробнее https://jsonlines.org/).

### Что делает скрипт:

Первый проход:

1. Парсит содержимое строки.
2. Воссоздает полную структуру лога (разворачивает вложенные JSON и XML-объекты, хранящиеся в строках).
3. Агрегирует имена ключей и сохраняет данные в промежуточном временном файле.

Второй проход:

4. Вынимает из временного файла данные построчно.
5. Выравнивает данные во соответствии с агрегированными заголовками.
6. Генерирует схему таблицы для PostgreSQL.
7. Генерирует CSV с данными.

### Установка и запуск

1. Клонировать репозиторий локально `git clone https://github.com/creadone/log2pg`
2. Установить пакеты `bundle install`
3. Скопировать файл логов в репозиторий
4. Запустить обработку `bundle exec ruby index.rb file.jsonl`
