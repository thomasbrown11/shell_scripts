for job in $(jobs -p);
do
kill -s SIGTERM $job > /dev/null 2>&1 || kill -9 $job > /dev/null 2>&1 &


