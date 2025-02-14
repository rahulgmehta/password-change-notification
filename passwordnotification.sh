#!/bin/bash

# Configuration: Set password expiration policy
password_expiry_warning_days=5  # Start warning 5 days before expiry
check_interval_hours=8  # Notify every 8 hours

# Function to get the password age
get_password_age() {
    # Get the username of the currently logged-in user
    username=$(whoami)

    # Get the last password change time using dscl command
    last_password_change=$(dscl . -read /Users/$username passwordPolicyLastModified | awk '{print $2, $3, $4, $5}')
    
    # If there's an error fetching the last password change date
    if [ -z "$last_password_change" ]; then
        echo "Error: Unable to retrieve last password change date."
        exit 1
    fi

    # Convert the last password change date to epoch timestamp
    last_password_change_epoch=$(date -j -f "%b %d %Y" "$last_password_change" +%s)
    
    echo $last_password_change_epoch
}

# Function to calculate the password expiration date
calculate_password_expiry_date() {
    # Assuming the password policy is 90 days
    password_expiry_days=90
    
    # Add the expiration days to the last password change date
    expiry_date_epoch=$(($1 + 86400 * $password_expiry_days))
    
    echo $expiry_date_epoch
}

# Function to send a password expiration warning
send_password_expiry_warning() {
    osascript -e 'display notification "Your password will expire soon. Please change your password." with title "Password Expiry Warning"'
}

# Function to check if the password is within the warning period
is_password_near_expiry() {
    current_epoch=$(date +%s)
    days_left=$((($1 - $current_epoch) / 86400))
    
    # Check if the password is within the warning period
    if [ $days_left -le $password_expiry_warning_days ] && [ $days_left -gt 0 ]; then
        return 0  # Password is near expiry
    else
        return 1  # Password is not near expiry
    fi
}

# Main loop to check password expiry and notify user
while true; do
    # Get the last password change time
    last_password_change_epoch=$(get_password_age)
    
    # Calculate password expiry date
    expiry_date_epoch=$(calculate_password_expiry_date $last_password_change_epoch)
    
    # Check if the password is within the warning period
    if is_password_near_expiry $expiry_date_epoch; then
        send_password_expiry_warning
    fi
    
    # Wait for the next check (8 hours)
    sleep $((check_interval_hours * 3600))  # Convert hours to seconds
done
