freeSpaceRequirement(){
	freespace=$(df -h -m | grep -m 1 /System/Volumes/Data | awk '{print $4}')
    if [[ $freespace -lt 15000 ]]; then
    	echo "Insufficient free space"
		return 1
	else
		echo "Machine has at least 15 GBs of free space"
	fi
}
freeSpaceRequirement

echo $(($freespace/1000))
