#  Developer Documentation

This document provides developer-oriented instructions for setting up, building, and maintaining the Inception architecture.

##  1. Prerequisites & Host Setup

To successfully run and develop this project, the host machine (Debian/Ubuntu VM) must have the following configured:

1.  **Docker & Docker Compose:** Docker Engine and the Compose V2 plugin (`docker-compose-plugin`) must be installed.
2.  **Make:** The `make` utility must be installed to execute the project's automation scripts.
3.  **Local DNS:** The host machine must route the project domain to the local loopback address. Add the following line to `/etc/hosts`:
    `127.0.0.1 ykhoussi.42.fr`

##  2. Repository Setup

1.  Clone the repository to your local machine.
2.  Navigate to the `srcs/` directory and ensure the `.env` file is present and properly populated with all necessary variables (Database, WordPress, and FTP credentials).
3.  Ensure the environment variables match the expected variables in the `docker-compose.yml` file.

##  3. Makefile Usage

The `Makefile` at the root of the repository abstracts complex Docker commands into simple execution targets:

*   `make` or `make all`: Creates the necessary volume directories on the host (`/home/ykhoussi/data/mariadb` and `/home/ykhoussi/data/wordpress`), builds the images using `--no-cache` to ensure clean layers, and brings up the stack in detached mode (`-d`).
*   `make down`: Executes `docker compose down -v --remove-orphans`. This stops the containers and removes the network.
*   `make clean`: Runs `make down` and executes `docker system prune -a -f` to strip the Docker environment of unused images and containers.
*   `make fclean`: Runs `make clean`, then aggressively removes all Docker volumes and forcibly deletes the persistent data stored in the host volume directories (`sudo rm -rf /home/ykhoussi/data/mariadb/*` and `/home/ykhoussi/data/wordpress/*`).
*   `make re`: Executes `fclean` followed immediately by `all` to provide a completely fresh build environment.

##  4. Docker Compose Commands

If you need to bypass the Makefile for granular debugging, navigate to the `srcs/` directory and use the following Compose V2 commands:

*   **Build a specific service:** `docker compose build --no-cache <service_name>`
*   **Start the stack:** `docker compose up -d`
*   **View real-time logs:** `docker compose logs -f <service_name>`
*   **Execute a shell inside a container:** `docker exec -it <container_name> bash` (or `sh` for Alpine-based containers).

##  5. Data Persistence & Volumes

Data persistence is handled via local Docker volumes bound to specific host directories. This ensures that container recreation does not result in data loss.

*   **Database Volume:** The `mariadb_data` volume is bound to `/home/ykhoussi/data/mariadb` on the host and mapped to `/var/lib/mysql` inside the MariaDB container.
*   **Web Files Volume:** The `wordpress_data` volume is bound to `/home/ykhoussi/data/wordpress` on the host and mapped to `/var/www/html` inside both the WordPress and NGINX containers (as well as the FTP container for file transfers). 

*Note: If permissions issues arise (e.g., Redis drop-in write failures), verify that the initialization scripts are correctly assigning `www-data` ownership to the mounted WordPress volume.*