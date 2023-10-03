#!/bin/bash

# Установите токен вашего бота
BOT_TOKEN="6427718017:AAHj_iG7b1FiHJzSo9TzjpwAu-k9xK6-NhM"

# Задайте URL для отправки сообщений в чат
SEND_MESSAGE_URL="https://api.telegram.org/bot$BOT_TOKEN/sendMessage"

# ID вашего чата, куда бот будет отправлять сообщения
CHAT_ID="-1001770053832"

# API ключ
API_KEY="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"

# Текст, который вы хотите передать в качестве запроса
REQUEST_TEXT="Расскажи утренний анекдот на случайную тему"

# URL API ChatGPT
API_URL="https://api.openai.com/v1/chat/completions"

#Начальное число пользователей
PREVIOUS_MEMBERS_COUNT="0"

# Функция отправки сообщения в чат
send_message() {
  local message="$1"
  curl -s -X POST "$SEND_MESSAGE_URL" -d "chat_id=$CHAT_ID" -d "text=$message"
}

# Функция выполнения запроса к API ChatGPT
generate_gpt_response() {
  local request_text="$1"
  local response=$(curl -s -X POST "$API_URL" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
       "model": "gpt-3.5-turbo",
       "temperature": 0.9,
       "messages": [{"role": "user", "content": "'"$request_text"'"}],
       "max_tokens": 35
     }')
  echo $response
  local generated_text=$(echo "$response" | jq -r '.choices[0].message.content')
  echo "$generated_text"
}

# Функция для обработки новых участников чата
handle_new_members() {
  local current_members_count="$1"
  if [[ "$PREVIOUS_MEMBERS_COUNT" != "0" && "$current_members_count" > "$PREVIOUS_MEMBERS_COUNT" ]]; then
    local new_members_count=$((current_members_count - PREVIOUS_MEMBERS_COUNT))
    local message="Привет! Расскажи свой любимый анекдот)"
    send_message "$message"
    echo "new member"
    PREVIOUS_MEMBERS_COUNT="$current_members_count"
  fi
}

# Функция для отправки утреннего анекдота
send_morning_joke() {
  local generated_text="$1"
  local morning_joke="Утренний анекдот от AI: $generated_text"
  send_message "$morning_joke"
}

# Основной цикл для получения обновлений чата
while true; do
  echo "start"
  
  # Запрос на получение обновлений
  updates=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getUpdates")
  
  # Извлечение текста последнего сообщения (если оно есть)
  LAST_MESSAGE_TEXT=$(echo "$updates" | jq -r '.result[-1].message.text')

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
  CURRENT_TIME=$(date "+%H:%M")
  CURRENT_DATE=$(date +"%Y-%m-%d")
  
  # Время, с которым мы сравниваем (например, 11:00)
  COMPARISON_TIME="11:00"
  
  # Проверяем, является ли текущее время 11:00
  if [[ "$CURRENT_DATE" != "$PREVIOUS_DATA" && "$CURRENT_TIME" > "$COMPARISON_TIME" ]]; then
    REQUEST_TEXT="Очень короткий анекдот на случайную тему на 10 слов"
    GENERATED_TEXT=$(generate_gpt_response "$REQUEST_TEXT")
    echo "$GENERATED_TEXT"
  
    send_morning_joke "$GENERATED_TEXT"
  
    # Установка новой даты последней отправки
    PREVIOUS_DATA="$CURRENT_DATE"
  fi
  
  # Пауза между проверками
  sleep 5
done
