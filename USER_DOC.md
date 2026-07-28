#  User & Administrator Documentation

This document provides basic usage instructions for end-users and administrators managing the Inception infrastructure.

##  1. Starting and Stopping the Stack

The infrastructure is managed via a `Makefile` for simplicity.

*   **To start the stack:** Run `make` in the root directory. This will automatically build the images and launch the containers in the background.
*   **To stop the stack:** Run `make down`. This safely shuts down the containers and the network without deleting your persistent website or database data.

##  2. Accessing the Website and Services

Once the stack is running, you can access the various services using your browser:

*   **Main Website:** Navigate to `https://ykhoussi.42.fr`
*   **WordPress Admin Panel:** Navigate to `https://ykhoussi.42.fr/wp-admin`
*   **Static Website (Bonus):** Navigate to `https://ykhoussi.42.fr/static/`
*   **Database Management (Adminer - Bonus):** Navigate to `https://ykhoussi.42.fr/adminer/`
*   **System Telemetry (cAdvisor - Bonus):** Navigate to `https://ykhoussi.42.fr/cadvisor/`

*(Note: Because the NGINX SSL certificate is self-signed, your browser will display a security warning. You must click "Advanced" and proceed to the site).*

##  3. Managing Credentials

All sensitive credentials and configurations are centralized in a `.env` file located at `srcs/.env`. 

To update passwords or users, you must edit this file **before** starting the stack. The file includes:
*   **Database Credentials:** `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD`.
*   **WordPress Users:** `WP_ADMIN_USER`, `WP_ADMIN_PASSWORD`, `WP_USER`, `WP_USER_PASSWORD`.
*   **FTP Users:** `FTP_USER`, `FTP_PASSWORD`.

*Warning: Changing these credentials after the database has already been initialized will not retroactively update the existing database. You must perform a deep clean (`make fclean`) to apply new credentials.*

##  4. Basic Checks & Usage

*   **Check running services:** Run `docker ps` in your terminal to verify that all containers (e.g., `nginx`, `wordpress`, `mariadb`, `redis`, `ftp`) are reporting an "Up" status.
*   **Accessing FTP (Bonus):** You can upload or download files directly to the WordPress directory using an FTP client (like FileZilla or the command line). Connect to `127.0.0.1` on port `21` using the credentials defined in your `.env` file.
*   **Verify Redis Cache (Bonus):** Log in to the WordPress Admin panel, navigate to **Settings > Redis**, and verify the status says "Connected" and the filesystem is "Writeable".