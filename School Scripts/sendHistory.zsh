#!/bin/zsh

jamfProUrl=https://mdirss.jamfcloud.com:443/JSSResource

jamfCreds=user:pw


loggedInUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')
mySerial=$(system_profiler SPHardwareDataType | awk '/Serial Number/{print $4}')
deviceID=$(curl -sku ${jamfCreds} -X GET -H "accept: application/xml" "${jamfProUrl}/computers/serialnumber/${mySerial}" | xmllint --xpath '//general/id/text()' -)
uploadDate=$(date +"%y%m%d%I%M%S")

dbLocationGoogle=/Users/${loggedInUser}/Library/Application\ Support/Google/Chrome
dbLocationOpera=/Users/${loggedInUser}/Library/Application\ Support/com.operasoftware.Opera
dbLocationSafari=/Users/${loggedInUser}/Library/Safari

logTmpLocation="/var/tmp/${uploadDate}_${loggedInUser}_BrowserHistory"
mkdir $logTmpLocation

googlecount=0
operacount=0
safaricount=0

echo "Creating SQL Files for use"
#Create Chromium Database SQL Query File
cat > "$logTmpLocation/Chromium.sql" << EOF
SELECT
  datetime(last_visit_time/1000000-11644473600, "unixepoch") as last_visited,
  url,
  title,
  visit_count
FROM urls
ORDER BY last_visit_time DESC;
EOF

#Create Safari Database SQL Query File
cat > "$logTmpLocation/Safari.sql" << EOF
SELECT
  datetime(hv.visit_time + 978307200, 'unixepoch', 'localtime') as last_visited,
  hi.url,
  hv.title
FROM
  history_visits hv,
  history_items hi
WHERE
  hv.history_item = hi.id
ORDER BY
  hv.visit_time DESC;
EOF

# Process safari profiles found
echo "Processing Safari Profiles
"
osascript -e 'display dialog "Safari will now close for maintenance." with title "MDIRSS Device Maintenance" buttons {"OK"} default button 1'
killall "Safari"
for file in ${dbLocationSafari}/History.db(N.);
{
    validfile="(.db)$"
    if [[ $file =~ $validfile ]] {
        filename=${logTmpLocation}/Safari-History${safaricount}
        echo "  Copying file to tmp location ${filename}"
        ditto $file ${filename}.db
        sqlite3 -header -csv $filename.db < $logTmpLocation/Safari.sql > $filename.csv; # process DB to CSV
        echo "  Converted Safari DB $safaricount to CSV
        -------"
        ((safaricount++))
    }
}

# Gather and Process Google profiles found
echo "Processing Google Chrome Profiles
"
osascript -e 'display dialog "Google Chrome will now close for maintenance." with title "MDIRSS Device Maintenance" buttons {"OK"} default button 1'
killall "Google Chrome"
for file in ${dbLocationGoogle}/**/*History(N.);
{
    filefolder=$( echo $(dirname "$file") ) # Get folder path
    profilename=$( echo $(basename "$filefolder") ) # Get last item in the path
    comp_profilename=$(sed "s/ //g" <<< $profilename) # Compress the profile name to remove spaces
    filename=${logTmpLocation}/Chrome-${comp_profilename}-History
    if [[ ${comp_profilename} != 'GuestProfile' && ${comp_profilename} != 'SystemProfile' ]] {
        echo "  Processing ${file}"
        echo "      Copying file to tmp location ${filename}"
        ditto $file ${filename}.db
        sqlite3 -header -csv $filename.db < $logTmpLocation/Chromium.sql > $filename.csv;
        ((googlecount++))
        echo "      Converted $comp_profilename DB to CSV
        -------"
    }
}

# Gather and Process Opera profiles found
echo "Processing Opera (GX & non GX) Profiles"
for file in ${dbLocationOpera}*/History(N.);
{
    GX=""
    if [[ $file =~ '[GX]' ]] {
        GX="GX"
    }
    filename=${logTmpLocation}/Opera$GX-${comp_profilename}-History
    ditto $file ${filename}.db
    sqlite3 -header -csv $filename.db < $logTmpLocation/Chromium.sql > $filename.csv;
    ((operacount++))
}

echo "
____________________

Browser History Process Complete

    Run Date & Time: $uploadDate
    Logged on User:  $loggedInUser

    Processed the following files:
    Google: $googlecount
    Opera:  $operacount
    Safari: $safaricount
_____________________
"

echo "Removing Parsed DB files"
rm -rf $logTmpLocation/*.sql
rm -rf $logTmpLocation/*.db*

echo "Zipping and Uploading CSV's"
zipfilename=${uploadDate}_${loggedInUser}_BrowserHistory
cd $logTmpLocation/ && zip -r $logTmpLocation/$zipfilename.zip ./* && cd -

# Upload zip of csv's to jamf Inventory Record - Attachments
curl -sku ${jamfCreds} "${jamfProUrl}/fileuploads/computers/id/${deviceID}" -F name=@${logTmpLocation}/$zipfilename.zip

# Cleanup files and remove tmp directory
echo "Cleaning Up"
rm -rf $logTmpLocation
