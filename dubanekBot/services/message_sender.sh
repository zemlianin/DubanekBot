send_message() {
  send_message_url="https://api.telegram.org/bot$BOT_TOKEN/sendMessage"

  local message="$1"
  echo "$send_message_url" -d "chat_id=$CHAT_ID" -d "text=$message"
  curl -s -X POST "$send_message_url" -d "chat_id=$CHAT_ID" -d "text=$message"
}


while true; do
  echo "start message sender"

  # Запрос на выборку данных с флагом is_sent=0
  QUERY="SELECT * FROM messages_for_send WHERE is_sent = 0"

  mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -s -e "$QUERY" | while IFS=$'\t' read -r id timestamp data is_sent producer_id; do
    echo "$data"
    echo "=============================="
    send_message "$data"

    return_code=$?
    echo $return_code

    if [[ $return_code -eq 0 ]]; then
      mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "UPDATE messages_for_send SET is_sent = 1 WHERE id = $id"
    else
        echo "Ошибка при отправке сообщения"
    fi
  done
  sleep 5
done