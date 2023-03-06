chip(){
	chiptype=$(sysctl -n machdep.cpu.brand_string)
    if [[ $chiptype == 'Apple M1' || $chiptype == 'Apple M2' ]]; then
    	echo "Apple Silicon"
		return 0
	else
		echo "Intel"
        return 1
	fi
}
chip

echo $?
#echo $(($freespace/1000))
