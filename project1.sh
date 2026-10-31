#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "Ошибка: Необходимо передать путь к CSV файлу."
    echo "Использование: ./project1.sh dataset.csv"
    exit 1
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
    echo "Ошибка: Файл '$FILE' не найден."
    exit 1
fi

DB_FILE="temp_db.sqlite"
rm -f "$DB_FILE"

sqlite3 "$DB_FILE" <<EOF
.mode csv
.import "$FILE" bids
EOF

echo "=================================================="
echo "ОТЧЕТ ПО БИРЖЕ ТРУДА (Только SQL)"
echo "=================================================="

echo -e "\n1. Статистика по регионам (Сумма бюджета и кол-во заявок):"
sqlite3 -header -column "$DB_FILE" <<EOF
SELECT 
    region AS 'Регион',
    COUNT(*) AS 'Кол-во заявок',
    SUM(budget_rub) AS 'Общий бюджет (руб)'
FROM bids
GROUP BY region
ORDER BY SUM(budget_rub) DESC;
EOF

echo -e "\n2. Средний чек по категориям (без учета выполненных):"
sqlite3 -header -column "$DB_FILE" <<EOF
SELECT 
    category AS 'Категория',
    COUNT(*) AS 'Активных',
    CAST(AVG(budget_rub) AS INT) AS 'Средний бюджет'
FROM bids
WHERE status != 'Выполнено'
GROUP BY category
ORDER BY AVG(budget_rub) DESC;
EOF

echo -e "\n3. Топ-3 самые дорогие заявки на бирже:"
sqlite3 -header -column "$DB_FILE" <<EOF
SELECT 
    title AS 'Название заявки',
    region AS 'Регион',
    budget_rub AS 'Бюджет',
    status AS 'Статус'
FROM bids
ORDER BY budget_rub DESC
LIMIT 3;
EOF

echo -e "\n=================================================="
echo "Обработка завершена."
rm -f "$DB_FILE"
