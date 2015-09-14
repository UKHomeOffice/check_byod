#!/bin/sh

SERVICE_RESULT=()

# Function for checking specific things
check_on() {
  local service=$1
  local command=$2
  local check=$3
  eval $command | grep -i "${check}" >/dev/null 2>&1 && status="on" || status="off"
  SERVICE_RESULT+=("${service}: ${status}")  
}

if [[ $UID -ne 0 ]]; then
  echo "This script needs to be run as root (with sudo)"
  exit 1
fi

# Check the services here only if they are on or off
# just add to the list
#
check_on "Firewall" "/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate" "enabled"
check_on "Disk Encryption" "fdesetup status" "on"
check_on "OS Updates Schedule" "softwareupdate --schedule" "on"
check_on "Remote Login" "systemsetup -getremotelogin" "on"
check_on "Auto Login" "defaults read /Library/Preferences/com.apple.loginwindow" "autoLoginUser"
check_on "Admin System Preference Auth" "security authorizationdb read system.preferences" "Checked by the Admin framework"
check_on "Screen Saver Password" "defaults read ~/Library/Preferences/com.apple.screensaver.plist" "askForPassword"

if [[ $(systemsetup -getdisplaysleep | grep -oE '[[:digit:]]+') -gt 5 ]]; then

  SERVICE_RESULT+=("Display Sleep Time: Greater than 5 minutes")
fi

# Mount the recovery disk and check if firmware is set
#
diskutil mount Recovery\ HD > /dev/null 2>&1
RECOVERY=$(hdiutil attach /Volumes/Recovery\ HD/com.apple.recovery.boot/BaseSystem.dmg | grep -i Base | cut -f 3)
"$RECOVERY/Applications/Utilities/Firmware Password Utility.app/Contents/Resources/setregproptool" -c || SERVICE_RESULT+=("Firmware Password: Not Set")
diskutil umount "/Volumes/OS X Base System"
diskutil umount force "/Volumes/Recovery HD"

echo ""
echo "---------- SERVICE STATUS -------------"
for service in "${SERVICE_RESULT[@]}"; do
  echo "${service}"
done
