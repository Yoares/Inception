# 🐳 Inception Setup & Evaluation Guide

*This project has been created as part of the 42 curriculum by ykhoussi.*

> The goal of this project is to broaden your knowledge of system administration by using Docker. You will virtualize several Docker images, creating them in your new personal virtual machine.

---

## 📑 Table of Contents

1. [Environment & Prerequisites](https://www.google.com/search?q=%23environment--prerequisites)
2. [Docker Installation](https://www.google.com/search?q=%23docker-installation)
3. [Project Architecture](https://www.google.com/search?q=%23project-architecture)
4. [42 Inception Knowledge Map](https://www.google.com/search?q=%2342-inception-knowledge-map)
5. [Docker Compose Concepts](https://www.google.com/search?q=%23docker-compose-concepts)
6. [Services Breakdown](https://www.google.com/search?q=%23services-breakdown)
* [NGINX](https://www.google.com/search?q=%231-nginx)
* [WordPress & PHP-FPM](https://www.google.com/search?q=%232-wordpress--php-fpm)
* [MariaDB](https://www.google.com/search?q=%233-mariadb)
* [Redis Cache (Bonus)](https://www.google.com/search?q=%234-redis-cache-bonus)
* [FTP Server (Bonus)](https://www.google.com/search?q=%235-ftp-server-bonus)
* [Adminer (Bonus)](https://www.google.com/search?q=%236-adminer-bonus)
* [cAdvisor (Custom Bonus)](https://www.google.com/search?q=%237-cadvisor-custom-bonus)
* [Static Website (Bonus)](https://www.google.com/search?q=%238-static-website-bonus)


7. [Request Lifecycle & Boot Process](https://www.google.com/search?q=%23request-lifecycle--boot-process)
8. [Usage (Makefile)](https://www.google.com/search?q=%23usage)
9. [Diagnostics & Verification](https://www.google.com/search?q=%23diagnostics--verification)
10. [Current Progress](https://www.google.com/search?q=%23current-progress)

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

| Package | Purpose |
| --- | --- |
| `ca-certificates` | Verifies HTTPS certificates. |
| `curl` | Downloads files from the internet. |
| `gnupg` | Verifies package signatures (GPG keys). |
| `lsb-release` | Provides Debian distribution information. |

### 3. Add Docker's Official GPG Key & Repository

```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian \
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

The project is composed of multiple containers communicating strictly through a custom internal Docker network (`inception`).

```text
                Browser
                   │
              HTTPS (443)
                   │
                   ▼
              +-----------+
              |  NGINX    | ────▶ /static ────▶ [ Static Site ]
              +-----------+ ────▶ /adminer ───▶ [ Adminer ]
                   │        ────▶ /cadvisor ──▶ [ cAdvisor ]
       FastCGI (Port 9000)
                   │
                   ▼
              +-----------+        TCP (Port 6379)
              | PHP-FPM   | ─────────────────────▶ +-----------+
     FTP ───▶ | WordPress |                        |   Redis   |
              +-----------+ ◀───────────────────── +-----------+
                   │
         SQL (Port 3306)
                   │
                   ▼
              +-----------+
              | MariaDB   |
              +-----------+

```

| Service | Responsibility |
| --- | --- |
| **NGINX** | Reverse proxy, HTTPS termination, serves static files, forwards PHP requests. |
| **PHP-FPM** | Executes WordPress PHP scripts. |
| **MariaDB** | Stores all persistent WordPress data. |
| **Redis** | In-memory object caching to reduce database load. |
| **FTP** | File transfer protocol access to the WordPress volume[cite: 3]. |
| **Adminer** | Graphical interface for database management[cite: 3]. |
| **cAdvisor** | Host and container resource telemetry and monitoring[cite: 3]. |
| **Static Site** | Secondary lightweight web server hosting static assets[cite: 3]. |

---

## 🗺️ 42 Inception Knowledge Map

This map outlines the conceptual dependencies required to master and defend the architecture during the 42 evaluation.

### Linux Operating System Fundamentals

* Process Management (PID 1, Daemons, Signals)
* File Security (Users, Permissions, Groups)

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
* **Redis** (In-memory Object Cache, RESP Protocol, Port 6379)

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
* `DOMAIN_NAME`, `WP_ADMIN_USER`, `FTP_USER`, `FTP_PASSWORD`[cite: 3]

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

### 4. Redis Cache (Bonus)

An in-memory data structure store used to cache database query results, dramatically reducing load times.

* **`bind 0.0.0.0`**: Listens on all internal Docker network interfaces[cite: 3].
* **LRU Eviction**: Configured to drop the least recently used keys when memory limits are reached[cite: 3].
* **Integration**: Intercepts requests via a custom `object-cache.php` drop-in managed by WP-CLI[cite: 3].

### 5. FTP Server (Bonus)

A Very Secure FTP Daemon (`vsftpd`) container that allows direct file transfers to the WordPress volume[cite: 3].

* Listens on host port 21 for control and ports 21000-21010 for passive data connections[cite: 3].
* Configured to add the FTP user to the `www-data` group, ensuring files can be modified without causing permission conflicts with PHP-FPM or Redis[cite: 3].

### 6. Adminer (Bonus)

A lightweight database management tool running as a single PHP file[cite: 3].

* Served via PHP's built-in web server on internal port 8080[cite: 3].
* Routed securely through the main NGINX reverse proxy on the `/adminer` path[cite: 3].

### 7. cAdvisor (Custom Bonus Service)

Google's Container Advisor provides real-time resource usage and performance characteristics[cite: 3].

* Mounts read-only host system volumes (`/sys`, `/var/run`, `/var/lib/docker`) to analyze kernel cgroups and Docker API telemetry[cite: 3].
* Accessible via the `/cadvisor` path through the NGINX proxy[cite: 3].

### 8. Static Website (Bonus)

A simple HTML static site hosted on a dedicated lightweight NGINX container[cite: 3].

* Listens on internal port 80 and is routed securely via the main NGINX proxy on the `/static` path[cite: 3].

---

## 🔄 Request Lifecycle & Boot Process

### The HTTP Request Flow (With Cache)

```text
Browser ➔ HTTPS Request ➔ NGINX ➔ FastCGI (9000) ➔ PHP-FPM ➔ Checks Redis Cache
      IF CACHE MISS: ➔ SQL Queries (3306) ➔ MariaDB ➔ Store in Redis ➔ Render HTML ➔ NGINX ➔ Browser
      IF CACHE HIT:  ➔ Render HTML ➔ NGINX ➔ Browser (Skips MariaDB entirely)

```

### The WordPress Boot Process

```text
index.php ➔ wp-blog-header.php ➔ wp-load.php ➔ wp-config.php ➔ wp-settings.php 
➔ Load Plugins ➔ Load Theme ➔ Connect to MariaDB/Redis ➔ Execute Logic ➔ Render HTML

```

---

## 🚀 Usage

The project is managed entirely via the `Makefile` located at the root of the repository. *Note: All docker-compose commands have been migrated to the modern Compose V2 (`docker compose`).*

| Command | Action |
| --- | --- |
| `make` or `make all` | Builds the images and starts the containers in the background. |
| `make down` | Stops and removes the containers and network (keeps volumes). |
| `make clean` | Stops containers and removes images. |
| `make fclean` | Deep clean: Removes containers, images, networks, and wipes host volumes. |
| `make re` | Executes `fclean` followed by `all` for a completely fresh build. |

---

## 🔍 Diagnostics & Verification

Use these essential commands to verify the integrity and performance of the architecture during evaluations.

### 1. Redis Cache Metrics (Application Level)

To verify that WordPress is successfully communicating with Redis and to check the cache hit rate:

```bash
# Enter the WordPress container
docker exec -it wordpress bash
cd /var/www/html

# Check active connection status and drop-in validity
wp redis status --allow-root


```

### 2. Redis Socket Monitoring (Low Level)

To observe live TCP query interception in real-time while browsing the website:

```bash
# Attach directly to the Redis daemon's live output stream
docker exec -it redis redis-cli monitor

```

---

## ✅ Current Progress

### Docker Infrastructure

* [x] Docker Engine & Compose V2 installation
* [x] Custom Bridge Network
* [x] Host Bind Mount Volumes

### MariaDB

* [x] Custom Alpine/Debian Dockerfile
* [x] Configuration (`50-server.cnf`)
* [x] Initialization Bash Script
* [x] Persistent Volume mapping

### WordPress

* [x] PHP-FPM custom configuration
* [x] WP-CLI installation
* [x] Automatic Core Installation & User Creation
* [x] Database connection via `wp-config.php`

### NGINX

* [x] Custom Alpine/Debian Dockerfile
* [x] SSL/TLS generation via OpenSSL
* [x] Port 443 Restriction
* [x] Reverse Proxy routing to FastCGI

### Bonus Services

* [x] **Redis Cache:** Dedicated container, network binding, memory management, and `wp-cli` object cache drop-in integration[cite: 3].
* [x] **FTP Server:** `vsftpd` configured with passive mode and shared volume permissions[cite: 3].
* [x] **Static Website:** Dedicated secondary NGINX container serving static HTML[cite: 3].
* [x] **Adminer:** Database management UI routed through the main NGINX proxy[cite: 3].
* [x] **Custom Service (cAdvisor):** Live kernel-level container monitoring and telemetry[cite: 3].

### Documentation & Defense

* [x] Docker Setup & Fundamentals
* [x] Request Lifecycle & Architecture
* [x] Database Schemas
* [x] 42 Evaluation Knowledge Map