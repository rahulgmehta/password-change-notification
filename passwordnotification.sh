#!/bin/bash

# Step 1: Create the LaunchDaemon file in /Library/LaunchDaemons (system-wide)
sudo tee /Library/LaunchDaemons/com.password.expiration.plist << 'LD'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.password.expiration</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>/Users/Shared/password_expiration_check.sh</string>
    </array>
    <key>StartInterval</key>
    <integer>28800</integer>  <!-- 8 hours in seconds -->
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
LD

# Set the correct permissions for the system-level LaunchDaemon
sudo chown root:wheel /Library/LaunchDaemons/com.password.expiration.plist
sudo chmod 644 /Library/LaunchDaemons/com.password.expiration.plist

# Load the LaunchDaemon with root privileges using launchctl bootstrap
sudo launchctl bootstrap system /Library/LaunchDaemons/com.password.expiration.plist


# Step 2: Password Expiration Check


sudo tee /Users/Shared/password_expiration_check.sh << 'LD'
#!/bin/bash

# Get the logged-in user
Name_loggedInUser=$(stat -f %Su /dev/console)

# Read the accountPolicyData attribute
account_policy_data=$(dscl . -read /Users/$Name_loggedInUser dsAttrTypeNative:accountPolicyData)

# Extract the passwordLastSetTime value
lastdate=$(echo "$account_policy_data" | grep -A1 "<key>passwordLastSetTime</key>" | awk 'NR==2' | sed -e 's/<real>//' -e 's/<\/real>//' -e 's/^[ \t]*//')

# Convert the floating-point epoch time to an integer
epoch_time=$(echo "$lastdate" | awk '{print int($1)}')

# Get the current date in epoch time
currentDate=$(date +%s)

# Calculate the password expiration date (epoch time) (90 days after password last set)
passwordExpirationThreshold=90
expiration_epoch_time=$((epoch_time + passwordExpirationThreshold * 86400))

# Calculate the password expiration countdown in seconds
expiration_countdown_seconds=$((expiration_epoch_time - currentDate))

# Calculate the expiration countdown in days
expiration_countdown_days=$((expiration_countdown_seconds / 86400))

# Print the password expiration countdown in days
echo "Password Expiration Countdown (days): $expiration_countdown_days"

# Function to display AppleScript warning
function show_warning() {
    osascript -e "tell application \"System Events\" to display dialog \"$1\" buttons {\"OK\"} default button 1"
}

# Check if the expiration countdown is less than 89 days
if [ "$expiration_countdown_days" -lt 89 ] && [ "$expiration_countdown_days" -gt 0 ]; then
    # If less than 89 days, show a warning
    warning_message="Warning: Your password will expire in $expiration_countdown_days days!"
    echo "$warning_message"
    show_warning "$warning_message"
elif [ "$expiration_countdown_days" -le 0 ]; then
    # If the password has already expired
    expired_message="Warning: Your password has already expired!"
    echo "$expired_message"
    show_warning "$expired_message"
fi
LD

bash /Users/Shared/password_expiration_check.sh
