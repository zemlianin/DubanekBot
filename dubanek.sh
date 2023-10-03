#!/bin/bash

# Установите токен вашего бота
BOT_TOKEN="6427718017:AAHj_iG7b1FiHJzSo9TzjpwAu-k9xK6-NhM"

# Задайте URL для отправки сообщений в чат
SEND_MESSAGE_URL="https://api.telegram.org/bot$BOT_TOKEN/sendMessage"

# ID вашего чата, куда бот будет отправлять сообщения
CHAT_ID="-1001770053832"

# API ключ
API_KEY=""

# Текст, который вы хотите передать в качестве запроса
REQUEST_TEXT="Расскажи утренний анекдот на случайную тему"

# URL API ChatGPT
API_URL="https://api.openai.com/v1/chat/completions"

#Количество пользователей на момент последнего сообщения
PREVIOUS_MEMBERS_COUNT=0

PREVIOUS_DATA=""

# Инициализация переменной для хранения текста последнего сообщения
LAST_MESSAGE_TEXT=""

# Получение обновлений чата с использованием long polling
while true; do

  echo start

  # Запрос на получение обновлений
  UPDATES=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getUpdates")

  # Извлечение текста последнего сообщения (если оно есть)
  LAST_MESSAGE_TEXT=$(echo "$UPDATES" | jq -r '.result[-1].message.text')

  echo checking

  # Проверка наличия новых сообщений и их текста
  if [[ "$UPDATES" != '{"ok":true,"result":[]}' && -n "$LAST_MESSAGE_TEXT" ]]; then

    echo $LAST_MESSAGE_TEXT

	# Отправляем запрос к API Telegram для получения информации о количестве участников 
    CURRENT_MEMBERS_COUNT=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getChatMembersCount?chat_id=$CHAT_ID" | jq -r '.result')

	  echo $CURRENT_MEMBERS_COUNT

	  if [ "$CURRENT_MEMBERS_COUNT" -gt "$PREVIOUS_MEMBERS_COUNT" ]; then

        # Если количество участников увеличилось, то кто-то новый присоединился
        NEW_MEMBERS_COUNT=$((CURRENT_MEMBERS_COUNT - PREVIOUS_MEMBERS_COUNT))
        echo "$NEW_MEMBERS_COUNT new members joined the chat"
	  
	      # Отправка приветствия
        MESSAGE="Привет! Расскажи свой любимый анекдот)"
        curl -s -X POST "$SEND_MESSAGE_URL" -d "chat_id=$CHAT_ID" -d "text=$MESSAGE"

        # Обновляем значение PREVIOUS_MEMBERS_COUNT
        PREVIOUS_MEMBERS_COUNT="$CURRENT_MEMBERS_COUNT"
    fi

	  PREVIOUS_MEMBERS_COUNT=$CURRENT_MEMBERS_COUNT
  fi

  # Получаем текущее время в формате часы:минуты
  CURRENT_TIME=$(date "+%H:%M")
  CURRENT_DATE=$(date +"%Y-%m-%d")

  # Время, с которым мы сравниваем (например, 11:00)
  COMPARISON_TIME="11:00"
  # Проверяем, является ли текущее время 11:00
  if [[ "$CURRENT_DATE" != "$PREVIOUS_DATA" && "$CURRENT_TIME" > "$COMPARISON_TIME" ]]; then
    # Отправка запроса с использованием curl
    REQUEST_TEXT="Очень короткий анекдот на случайную тему на 10 слов"
    RESPONSE=$(curl -s -X POST "$API_URL" \
         -H "Authorization: Bearer $API_KEY" \
         -H "Content-Type: application/json" \
         -d '{
           "model": "gpt-3.5-turbo",
	   "temperature": 0.9,
	   "messages": [{"role": "user", "content": "'"$REQUEST_TEXT"'"}],
           "max_tokens": 35
         }')

    echo $RESPONSE
    # Извлечение и вывод ответа
    GENERATED_TEXT=$(echo $RESPONSE | jq -r '.choices[0].message.content')

    morning_joke="Утренний анекдот от AI: $GENERATED_TEXT"

    echo $morning_joke
    # Отправка утреннего анекдота
    curl -s -X POST "$SEND_MESSAGE_URL" -d "chat_id=$CHAT_ID" -d "text=$morning_joke"

    # Установка новой даты последней отправки
    PREVIOUS_DATA=$CURRENT_DATE
  fi

  # Пауза между проверками
  sleep 5
done



# Если текст последнего сообщения содержит оповещение о добавлении нового участника
# if [[ "$LAST_MESSAGE_TEXT" == *"new_chat_participant"* ]]; then

#  echo it is new participant

#   # Отправка приветственного сообщения
#   MESSAGE="Hello! Tell your favorite joke"
#   curl -s -X POST "$SEND_MESSAGE_URL" -d "chat_id=$CHAT_ID" -d "text=$MESSAGE"

#   # Очистка обновлений
#   curl -s "https://api.telegram.org/bot$BOT_TOKEN/getUpdates" > /dev/null
# fi
