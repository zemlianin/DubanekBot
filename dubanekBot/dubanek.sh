#!/bin/bash

# BOT_TOKEN="" #устанавливается внутри CI

# Задайте URL для отправки сообщений в чат
# SEND_MESSAGE_URL="https://api.telegram.org/bot$BOT_TOKEN/sendMessage"

# ID вашего чата, куда бот будет отправлять сообщения
# CHAT_ID устанавливается внутри CI

# API ключ
# API_KEY="" #устанавливается внутри CI

# Текст, который вы хотите передать в качестве запроса
REQUEST_TEXT="Расскажи утренний анекдот на случайную тему"

# URL API ChatGPT
API_URL="https://api.openai.com/v1/chat/completions"

#Начальное число пользователей
PREVIOUS_MEMBERS_COUNT="0"

export ROOT_PATH="/var/dubanek"


# Функция API отправки сообщения в чат
add_message() {
  local message="$1"
  local path="$0"
  
  current_timestamp=$(date +%s)
  
  if [[ $message == *"\""* ]]; then
    echo "SQL Инъекция!"
  else
    SQL_QUERY="INSERT INTO messages_for_send (timestamp, data, path) VALUES ($current_timestamp, \"$message\", \"$path\");"
    mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -D $DB_NAME --default-character-set=utf8 -s -e "$SQL_QUERY"
  fi
}
export -f add_message

# Функция API получения списка сообщений начиная с какого то timestamp
get_messages() {
  local timestamp="$1"
  
  QUERY="SELECT * FROM messages_for_read WHERE timestamp > $timestamp"

  mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -s -e "$QUERY" | while IFS=$'\t' read -r id timestamp data update_id; do
    echo "$id;$timestamp;$data;$update_id"
  done
}
export -f get_messages

# Функция API получения участников чата
get_members() {
  # Отправляем запрос к API Telegram для получения информации о количестве участников
  CURRENT_MEMBERS_COUNT=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getChatMembersCount?chat_id=$CHAT_ID" | jq -r '.result')
  echo $CURRENT_MEMBERS_COUNT
}
export -f get_members

# Функция API выполнения запроса к API ChatGPT
generate_gpt_response() {
  local request_text="$1"
  local response=$(curl -s -X POST "$API_URL" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
       "model": "gpt-3.5-turbo",
       "temperature": 0.9,
       "messages": [{"role": "user", "content": "'"$request_text"'"}],
       "max_tokens": 50
     }')
  local generated_text=$(echo "$response" | jq -r '.choices[0].message.content')
  echo "$generated_text"
}
export -f generate_gpt_response


# Функция для отправки утреннего анекдота
send_morning_joke() {
  local generated_text="$1"
  local morning_joke="Утренний анекдот от AI: $generated_text"
  # send_message "$morning_joke"
}

# Запуск сервисов бота
bash $ROOT_PATH/services/message_reader.sh &
bash $ROOT_PATH/services/message_sender.sh &
bash $ROOT_PATH/services/modules_runner.sh &


# Основной цикл для получения обновлений чата
while true; do
  echo "start 1"

  #add_message ping
  sleep 5
  # Запрос на получение обновлений
  updates=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getUpdates")

  # Извлечение текста последнего сообщения (если оно есть)
  LAST_MESSAGE_TEXT=$(echo "$updates" | jq -r '.result[-1].message.text')

  LAST_MESSAGE_TIMESTAMP=$(echo "$updates" | jq -r '.result[-1].message.date')


  echo "checking"

  # Проверка наличия новых сообщений и их текста
  if [[ "$updates" != '{"ok":true,"result":[]}' && -n "$LAST_MESSAGE_TEXT" ]]; then
    echo "$LAST_MESSAGE_TEXT"

    # Отправляем запрос к API Telegram для получения информации о количестве участников
    CURRENT_MEMBERS_COUNT=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getChatMembersCount?chat_id=$CHAT_ID" | jq -r '.result')

    echo "$CURRENT_MEMBERS_COUNT"

    handle_new_members "$CURRENT_MEMBERS_COUNT"
    PREVIOUS_MEMBERS_COUNT="$CURRENT_MEMBERS_COUNT"
  fi
  
  # Получаем текущее время в формате часы:минуты
  CURRENT_TIME_H=$(date "+%H")
  CURRENT_DATE=$(date "+%Y-%m-%d")

  # Время, с которым мы сравниваем (например, 11:00)
  COMPARISON_TIME_H="9"
  COMPARISON_TIME_M="0"
  echo $CURRENT_TIME_H
  echo 
  # Проверяем, является ли текущее время 11:00
  if [[ "$CURRENT_DATE" != "$PREVIOUS_DATA" && "$CURRENT_TIME_H" -gt "$COMPARISON_TIME_H" ]]; then
    REQUEST_TEXT="Очень короткий анекдот на случайную тему на 10 слов"
    GENERATED_TEXT=$(generate_gpt_response "$REQUEST_TEXT")
    echo $GENERATED_TEXT
    send_morning_joke "$GENERATED_TEXT"

    # Установка новой даты последней отправки
    PREVIOUS_DATA="$CURRENT_DATE"
  fi

  # Пауза между проверками
  sleep 5
done