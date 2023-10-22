query="SELECT MAX(update_id)  FROM messages_for_read;"
query_count="SELECT COUNT(*) FROM messages_for_read LIMIT 1;"

# Выполняем запрос и сохраняем результат
offset=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -N -s -e "$query")
count=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -N -s -e "$query_count")

if [[ $count -eq '0' ]]; then
  offset=0
fi

while true; do
  echo "start message reader"

  # Запрос на получение обновлений
  updates=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getUpdates?offset=$offset")
  echo $updates
  echo $offset

  # Извлечение информации из последнего сообщения (если оно есть)
  LAST_MESSAGE_TEXT=$(echo "$updates" | jq -r '.result[-1].message.text')
  LAST_MESSAGE_TIMESTAMP=$(echo "$updates" | jq -r '.result[-1].message.date')
  LAST_UPDATE_ID=$(echo "$updates" | jq -r '.result[-1].update_id')

  LAST_MESSAGE_TEXT_DECODED=$(echo -e "$LAST_MESSAGE_TEXT")
  echo $LAST_MESSAGE_TEXT_DECODED

  offset=$((LAST_UPDATE_ID+1))

  if [[ $LAST_MESSAGE_TEXT_DECODED == *"\""* ]]; then
    echo "SQL Инъекция!"
  else
    SQL_QUERY="INSERT INTO messages_for_read (timestamp, data, update_id) VALUES ($LAST_MESSAGE_TIMESTAMP, \"$LAST_MESSAGE_TEXT_DECODED\", $LAST_UPDATE_ID);"
    mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -D $DB_NAME --default-character-set=utf8 -s -e "$SQL_QUERY"
  fi

  sleep 5
done