#!/bin/zsh

#osascript << EOF
#set input to text returned of (display dialog "Enter length of timer" default answer "")
#set countdown to input
#repeat input times
#	display notification "Time left: " & countdown giving up after 1
#	set countdown to countdown - 1
#end repeat
#beep
#EOF

countdown()

end=$1
    while [[ $((end > 0)) ]]
    do
        printf $end
        sleep 1
        $((end-=1))
    done

echo $now
echo $end

countdown() $1
