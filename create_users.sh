#!/bin/bash

# Log file and secure password file
LOG_FILE="/var/log/user_management.log"
SECURE_DIR="/var/secure"
SECURE_PASSWORD_FILE="$SECURE_DIR/user_passwords.csv"

# Ensure the secure directory exists and has the correct permissions
if [ ! -d "$SECURE_DIR" ]; then
    sudo mkdir -p "$SECURE_DIR"
    sudo chmod 700 "$SECURE_DIR"
fi

# Ensure the log directory exists
if [ ! -d "/var/log" ]; then
    sudo mkdir -p /var/log
fi

# Ensure the log file exists
sudo touch "$LOG_FILE"
sudo chmod 600 "$LOG_FILE"

# Ensure the secure password file exists
sudo touch "$SECURE_PASSWORD_FILE"
sudo chmod 600 "$SECURE_PASSWORD_FILE"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a "$LOG_FILE"
}

# Function to generate a random password
generate_password() {
    tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16
}

# Check if the file argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <name-of-text-file>"
    exit 1
fi

# Read the file line by line
while IFS=';' read -r username groups; do
    # Remove leading/trailing whitespace
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)

    # Check if user already exists
    if id -u "$username" >/dev/null 2>&1; then
        log_message "User $username already exists."
        continue
    fi

    # Create the personal group for the user
    sudo groupadd "$username"
    if [ $? -ne 0 ]; then
        log_message "Failed to create group $username."
        continue
    fi

    # Create the user with the personal group and home directory
    sudo useradd -m -g "$username" "$username"
    if [ $? -ne 0 ]; then
        log_message "Failed to create user $username."
        continue
    fi

    # Create and set the password
    password=$(generate_password)
    echo "$username:$password" | sudo chpasswd
    if [ $? -ne 0 ]; then
        log_message "Failed to set password for user $username."
        continue
    fi

    # Set up home directory permissions
    sudo chmod 700 "/home/$username"
    sudo chown "$username:$username" "/home/$username"

    # Add user to additional groups
    if [ -n "$groups" ]; then
        IFS=',' read -r -a group_array <<<"$groups"
        for group in "${group_array[@]}"; do
            group=$(echo "$group" | xargs)
            # Check if group exists, if not create it
            if ! getent group "$group" >/dev/null 2>&1; then
                sudo groupadd "$group"
                if [ $? -ne 0 ]; then
                    log_message "Failed to create group $group."
                    continue
                fi
            fi
            sudo usermod -aG "$group" "$username"
            if [ $? -ne 0 ]; then
                log_message "Failed to add user $username to group $group."
                continue
            fi
        done
    fi

    # Log successful creation
    log_message "Created user $username with groups $groups."

    # Store the password securely
    echo "$username,$password" | sudo tee -a "$SECURE_PASSWORD_FILE" >/dev/null

done <"$1"

# Secure the password file
sudo chmod 600 "$SECURE_PASSWORD_FILE"

log_message "User creation script completed."

exit 0
