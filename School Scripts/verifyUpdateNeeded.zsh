verifyUpdateNeeded(){
	# Check for available updates
    availableUpdates=`/usr/libexec/mdmclient AvailableOSUpdates`
    
    # Updates available
    if [[ "$availableUpdates" == *"=== OS Update Item ==="* ]]; then
    	echo "Updates Available"
    # Updates not available
    else
    	echo "No Updates Available"
        return 1
	fi
}
