PREVIOUS_MEMBERS_COUNT=0
CURRENT_MEMBERS_COUNT=0

# Функция для обработки новых участников чата
handle_new_members() {
  local current_members_count="$1"
  if [[ "$PREVIOUS_MEMBERS_COUNT" != "0" && "$current_members_count" > "$PREVIOUS_MEMBERS_COUNT" ]]; then
    local new_members_count=$((current_members_count - PREVIOUS_MEMBERS_COUNT))
    local message="Привет! Расскажи свой любимый анекдот)"
    # add_message "$message"
  fi
}

while true; do
# Проверка наличия новых сообщений и их текста
  # add_message "Чекаю юзеров"

  echo "check_users_module runing"

  # Отправляем запрос к API Telegram для получения информации о количестве участников
  CURRENT_MEMBERS_COUNT=$(get_members)

  echo "$CURRENT_MEMBERS_COUNT"

  if [[ "$CURRENT_MEMBERS_COUNT" -gt "$PREVIOUS_MEMBERS_COUNT" && "$PREVIOUS_MEMBERS_COUNT" -ne "0" ]]; then
    handle_new_members "$CURRENT_MEMBERS_COUNT"
    PREVIOUS_MEMBERS_COUNT="$CURRENT_MEMBERS_COUNT"
  fi
  
  sleep 30
done