while true; do
# Проверка наличия новых сообщений и их текста
  if [[ "$updates" != '{"ok":true,"result":[]}' && -n "$LAST_MESSAGE_TEXT" ]]; then
    echo "$LAST_MESSAGE_TEXT"

    # Отправляем запрос к API Telegram для получения информации о количестве участников
    CURRENT_MEMBERS_COUNT=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getChatMembersCount?chat_id=$CHAT_ID" | jq -r '.result')

    echo "$CURRENT_MEMBERS_COUNT"

    handle_new_members "$CURRENT_MEMBERS_COUNT"
    PREVIOUS_MEMBERS_COUNT="$CURRENT_MEMBERS_COUNT"
  fi
done