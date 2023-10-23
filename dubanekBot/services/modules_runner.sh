cd $ROOT_PATH/moduls

run_command(){
    command= $1
    env -i \
    HOME="$HOME" TERM="$TERM" \
    'declare -f get_members' \
    'declare -f add_message' \
    'declare -f generate_gpt_response' \
    'declare -f get_messages' \
    $command 
}

# запуск процесса с очищенными переменными среды, нужно запускать модули только так
while true; do
  echo "start moduls runner"

  # Запрос на выборку данных с флагом is_sent=0
  QUERY="SELECT * FROM producers WHERE is_run = 0 AND is_deleted = 0"

  mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" --default-character-set=utf8 -s -e "$QUERY" | while IFS=$'\t' read -r id path pid compile_command run_command is_run is_compiled is_deleted; do
    
    echo "$path"
    
    if [[ $is_compiled -eq '0' ]]; then
        run_command $compile_command
        mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "UPDATE producers SET is_compiled = 1 WHERE id = $id"
    fi

    run_command $run_command &
    return_code=$?
    pid=$!

    echo "pid: $pid"

    if [[ "$return_code" -eq "0" ]]; then
      mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "UPDATE producers SET is_run = 1 WHERE id = $id"
      mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "UPDATE producers SET pid = $pid WHERE id = $id"
    else
        echo "Ошибка запуска"
    fi
  done
  sleep 5
done
