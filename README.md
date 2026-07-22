# 🐳 Inception Setup & Evaluation Guide

> **This project has been created as part of the 42 curriculum (1337 School).**  
> The goal of this project is to broaden your knowledge of system administration by using Docker. You will virtualize several Docker images, creating them in your new personal virtual machine.

---

## 📑 Table of Contents
1. [Environment & Prerequisites](#environment--prerequisites)
2. [Docker Installation](#docker-installation)
3. [Project Architecture](#project-architecture)
4. [42 Inception Knowledge Map](#42-inception-knowledge-map)
5. [Docker Compose Concepts](#docker-compose-concepts)
6. [Services Breakdown](#services-breakdown)
   - [NGINX](#1-nginx)
   - [WordPress & PHP-FPM](#2-wordpress--php-fpm)
   - [MariaDB](#3-mariadb)
7. [Request Lifecycle & Boot Process](#request-lifecycle--boot-process)
8. [Usage (Makefile)](#usage)
9. [Current Progress](#current-progress)

---

## 🖥️ Environment & Prerequisites

* **OS:** Debian 13 (Trixie) / Ubuntu (Configured via Virtual Machine)
* **Domain:** `ykhoussi.42.fr` mapped to `127.0.0.1` in `/etc/hosts`

---

## 🐋 Docker Installation

### 1. Update the package index
```bash
sudo apt update
```
*Refreshes the local package database so APT knows about the latest available packages.*

### 2. Install required dependencies
```bash
sudo apt install -y ca-certificates curl gnupg lsb-release
```
| Package           | Purpose                                   |
| ----------------- | ----------------------------------------- |
| `ca-certificates` | Verifies HTTPS certificates.              |
| `curl`            | Downloads files from the internet.        |
| `gnupg`           | Verifies package signatures (GPG keys).   |
| `lsb-release`     | Provides Debian distribution information. |

### 3. Add Docker's Official GPG Key & Repository
```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL [https://download.docker.com/linux/debian/gpg](https://download.docker.com/linux/debian/gpg) | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  [https://download.docker.com/linux/debian](https://download.docker.com/linux/debian) \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### 4. Install Docker Engine
```bash
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### 5. Post-Installation Configuration
Allow running Docker without `sudo` and verify the installation:
```bash
sudo usermod -aG docker $USER
# Log out and log back in for changes to take effect
docker --version
docker compose version
```

---

## 🏗️ Project Architecture

The mandatory project is composed of three containers communicating through a custom internal Docker network (`inception`).

```text
                Browser
                   │
              HTTPS (443)
                   │
                   ▼
              +-----------+
              |  NGINX    |
              +-----------+
                   │
       FastCGI (Port 9000)
                   │
                   ▼
              +-----------+
              | PHP-FPM   |
              | WordPress |
              +-----------+
                   │
         SQL (Port 3306)
                   │
                   ▼
              +-----------+
              | MariaDB   |
              +-----------+
```

| Service | Responsibility |
|---------|----------------|
| **NGINX** | Reverse proxy, HTTPS termination, serves static files, forwards PHP requests. |
| **PHP-FPM** | Executes WordPress PHP scripts. |
| **MariaDB** | Stores all persistent WordPress data. |

---

## 🗺️ 42 Inception Knowledge Map

This map outlines the conceptual dependencies required to master and defend the architecture during the 42 evaluation.

### Linux Operating System Fundamentals
* Process Management (PID 1, Daemons, Signals)
* File Security (Users, Permissions)

⬇️

### Containerization Primitives
* Isolation (Namespaces, cgroups)
* Storage (OverlayFS, Copy-on-write)

⬇️

### Docker Architecture
* Docker Engine (Daemon, Client, Images)
* Dockerfile Mechanics (ENTRYPOINT, RUN, CMD)

⬇️

### Docker Compose (Orchestration)
* Secrets Management (`.env`)
* Volume Persistence (Bind Mounts)
* Internal Networking (Bridge, Docker DNS)

⬇️

### The Inception Application Stack
* **NGINX** (Reverse Proxy, Event Loop, Port 443, TLS 1.3)
  * ↳ *FastCGI Protocol (Over internal Docker network)*
* **PHP-FPM / WordPress** (Logic Execution, WP-CLI, wp-config.php)
  * ↳ *SQL Queries (Over internal Docker network)*
* **MariaDB** (Relational Data, Privileges, Isolated Port 3306)

---

## ⚙️ Docker Compose Concepts

### Network
Docker automatically creates an internal DNS record for each service. No hardcoded IPs are required. NGINX can reach WordPress simply by resolving the hostname `wordpress`.
```yaml
networks:
  inception:
    driver: bridge
```

### Volumes
Volumes persist data even after containers are removed, satisfying the requirement that database and website files must survive container destruction.
```text
Host Machine: /home/<login>/data/mariadb
                         │
                         ▼
Container:    /var/lib/mysql
```

### Environment Variables
Sensitive configuration is injected securely at runtime via the `.env` file.
* `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD`
* `DOMAIN_NAME`, `WP_ADMIN_USER`

---

## 🛠️ Services Breakdown

### 1. NGINX
NGINX is the public-facing web server acting as the single entrypoint to the infrastructure.
* Accepts HTTPS on **443** strictly.
* Terminates SSL/TLS (Requires TLSv1.2 or TLSv1.3).
* Forwards PHP requests to PHP-FPM using FastCGI.

**Cryptography (OpenSSL):**
Generates a self-signed TLS certificate during the image build to encrypt traffic:
* `inception.key`: Private key kept secret by NGINX.
* `inception.crt`: Public certificate sent to browsers. *(Note: Browsers will show a warning as it is self-signed).*

### 2. WordPress & PHP-FPM
* **`php-mysql`**: The PHP extension allowing PHP to execute SQL queries against MariaDB.
* **WP-CLI**: Command-line interface used in the entrypoint script to automatically download WordPress, generate `wp-config.php`, and create the database tables, admin user, and secondary user.

**PHP-FPM Configuration (`www.conf`):**
```ini
listen = 9000           # Allows NGINX to communicate over TCP
pm = dynamic            # Dynamic worker management
pm.max_children = 5     # Maximum PHP workers
clear_env = no          # Allows PHP to read Docker's .env variables
```

### 3. MariaDB
The relational database storing Users, Posts, Pages, Comments, and Settings.
* **`bind-address = 0.0.0.0`**: Allows other containers in the `inception` network to connect.
* **`datadir = /var/lib/mysql`**: Location of database files mapped to the host volume.

**Startup Sequence:**
Checks if the DB exists ➔ Starts MariaDB temporarily ➔ Creates DB & Users ➔ Grants privileges ➔ Sets Root password ➔ Stops temporary server ➔ Restarts MariaDB in the foreground (PID 1).

---

## 🔄 Request Lifecycle & Boot Process

### The HTTP Request Flow
```text
Browser ➔ HTTPS Request ➔ NGINX ➔ FastCGI (9000) ➔ PHP-FPM ➔ SQL Queries (3306) ➔ MariaDB
MariaDB ➔ Data Return ➔ PHP-FPM ➔ Generates HTML ➔ NGINX ➔ Browser
```

### The WordPress Boot Process
```text
index.php ➔ wp-blog-header.php ➔ wp-load.php ➔ wp-config.php ➔ wp-settings.php 
➔ Load Plugins ➔ Load Theme ➔ Connect to MariaDB ➔ Execute Queries ➔ Render HTML
```

### The Database Structure
* `wp_posts`: Posts, pages, attachments.
* `wp_users` / `wp_usermeta`: User accounts and metadata.
* `wp_options`: Core site settings.

---

## 🚀 Usage

The project is managed entirely via the `Makefile` located at the root of the repository.

| Command | Action |
|---------|--------|
| `make` or `make all` | Builds the images and starts the containers in the background. |
| `make down` | Stops and removes the containers and network (keeps volumes). |
| `make clean` | Stops containers and removes images. |
| `make fclean` | Deep clean: Removes containers, images, networks, and wipes host volumes. |
| `make re` | Executes `fclean` followed by `all` for a completely fresh build. |

---

## ✅ Current Progress

### Docker Infrastructure
- [x] Docker Engine & Compose installation
- [x] Custom Bridge Network
- [x] Host Bind Mount Volumes

### MariaDB
- [x] Custom Alpine/Debian Dockerfile
- [x] Configuration (`50-server.cnf`)
- [x] Initialization Bash Script
- [x] Persistent Volume mapping

### WordPress
- [x] PHP-FPM custom configuration
- [x] WP-CLI installation
- [x] Automatic Core Installation & User Creation
- [x] Database connection via `wp-config.php`

### NGINX
- [x] Custom Alpine/Debian Dockerfile
- [x] SSL/TLS generation via OpenSSL
- [x] Port 443 Restriction
- [x] Reverse Proxy routing to FastCGI

### Documentation & Defense
- [x] Docker Setup & Fundamentals
- [x] Request Lifecycle & Architecture
- [x] Database Schemas
- [x] 42 Evaluation Knowledge Map