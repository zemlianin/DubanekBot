
echo result $count
while true; do
  echo "start message sender"

  # Запрос на выборку данных с флагом is_sent=0
  QUERY="SELECT * FROM messages_for_send WHERE is_sent = 0"

  # Выполнение запроса к базе данных
  RESULT=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -s -e "$QUERY")

  echo $RESULT
  for row in $RESULT; do
    echo "Processing row: $row"
    # Здесь вы можете вызывать функцию, передавая ей данные из каждой строки
    # function_name "$row"
  done
  sleep 5
done