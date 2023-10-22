# запуск процесса с очищенными переменными среды, нужно запускать модули только так
env -i HOME="$HOME" TERM="$TERM" /path/to/your_script.sh
