batteryCheck(){
	powerType=$(pmset -g batt | head -n 1 | cut -c19- | rev | cut -c 2- | rev)

	if [[ "$powerType" == "Battery Power" ]]; then
    	echo "Machine is on Battery Power."
		bat=$(pmset -g batt | grep 'InternalBattery' | awk '{print $3}' | tr -d '%'';')
        if (( $bat > 60 )); then
			echo "Battery Level OK, Continuing Update..."
		else
        	echo "Battery Level Insufficient for this update"
            return 1
		fi
	else
    	echo "Machine is on AC Power."
	fi
}
batteryCheck
