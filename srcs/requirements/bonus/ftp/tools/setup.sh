#!/bin/bash

# Check if the FTP user already exists to ensure idempotency
if ! id -u "$FTP_USER" > /dev/null 2>&1; then
    echo "Creating FTP user: $FTP_USER..."
    
    # Create the user, setting their home directory directly to the WordPress volume
    useradd -d /var/www/html -s /bin/bash "$FTP_USER"
    
    # Assign the password securely
    echo "$FTP_USER:$FTP_PASSWORD" | chpasswd
    
    # Add the FTP user to the www-data group so PHP can interact with uploaded files
    usermod -aG www-data "$FTP_USER"
    
    # Ensure ownership is correct so the FTP user can actually write to the directory
    chown -R "$FTP_USER":www-data /var/www/html
    
    echo "FTP user created and directory linked."
else
    echo "FTP user already exists. Skipping creation."
fi

# The PID 1 Handoff: Execute the daemon in the foreground
echo "Starting vsftpd daemon..."
exec vsftpd /etc/vsftpd.conf