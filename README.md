# Inception Setup Guide

> **This project has been created as part of the 42 curriculum.**

## Environment

* **OS:** Debian 13 (Trixie)
* **Virtual Machine:** Configured and running

---

# Docker Installation

## 1. Update the package index

```bash
sudo apt update
```

Refreshes the local package database so APT knows about the latest available packages.

---

## 2. Install required dependencies

```bash
sudo apt install -y ca-certificates curl gnupg lsb-release
```

Installs the tools required to securely download and verify packages from external repositories.

| Package           | Purpose                                   |
| ----------------- | ----------------------------------------- |
| `ca-certificates` | Verifies HTTPS certificates.              |
| `curl`            | Downloads files from the internet.        |
| `gnupg`           | Verifies package signatures (GPG keys).   |
| `lsb-release`     | Provides Debian distribution information. |

---

## 3. Create the APT keyring directory

```bash
sudo install -m 0755 -d /etc/apt/keyrings
```

Creates the directory used to store trusted repository signing keys.

---

## 4. Download Docker's GPG key

```bash
curl -fsSL https://download.docker.com/linux/debian/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

Downloads Docker's official GPG key and stores it in binary format so APT can verify Docker packages.

---

## 5. Add the Docker repository

```bash
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

Adds Docker's official package repository to APT.

---

## 6. Refresh package lists

```bash
sudo apt update
```

Updates APT so it recognizes packages available from the newly added Docker repository.

---

## 7. Install Docker Engine

```bash
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Installs Docker Engine and its required components.

| Package                 | Purpose                           |
| ----------------------- | --------------------------------- |
| `docker-ce`             | Docker Engine (daemon).           |
| `docker-ce-cli`         | Docker command-line interface.    |
| `containerd.io`         | Container runtime used by Docker. |
| `docker-buildx-plugin`  | Advanced image builder.           |
| `docker-compose-plugin` | Docker Compose v2 plugin.         |

---

## 8. Verify the Docker service

```bash
sudo systemctl status docker
```

Checks whether the Docker daemon is running.

Expected status:

```text
Active: active (running)
```

---

## 9. Verify the installation

```bash
docker --version
```

Displays the installed Docker version.

```bash
docker compose version
```

Displays the installed Docker Compose version.

---

## 10. Allow Docker without sudo

```bash
sudo usermod -aG docker $USER
```

Adds the current user to the `docker` group, allowing Docker commands to run without `sudo`.

> Log out and log back in (or reboot) for the group change to take effect.

---

## 11. Verify group membership

```bash
groups
```

Confirms that the current user belongs to the `docker` group.

---

# Inception Architecture

The mandatory project is composed of three containers communicating through a custom Docker network.

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
               |WordPress  |
               +-----------+
                    │
          SQL (Port 3306)
                    │
                    ▼
               +-----------+
               | MariaDB   |
               +-----------+
```

## Services

| Service | Responsibility |
|---------|----------------|
| NGINX | Reverse proxy, HTTPS termination, serves static files, forwards PHP requests. |
| PHP-FPM | Executes WordPress PHP scripts. |
| MariaDB | Stores all persistent WordPress data. |

---

# Docker Compose Concepts

## Services

Each container is defined as a service:

- nginx
- wordpress
- mariadb

Each service has its own:
- Filesystem
- Process
- Network namespace

## Network

```yaml
networks:
  inception:
    driver: bridge
```

Docker automatically creates DNS records.

Example:

```text
WordPress
    │
    ▼
Host: mariadb
```

No IP address is required.

## Volumes

```text
Host
/home/<login>/data/mariadb
          │
          ▼
Container
/var/lib/mysql
```

Volumes persist data even after containers are removed.

## Environment Variables

Sensitive configuration comes from `.env`.

Examples:

- MYSQL_DATABASE
- MYSQL_USER
- MYSQL_PASSWORD
- MYSQL_ROOT_PASSWORD
- DOMAIN_NAME
- WP_ADMIN_USER

---

# MariaDB

MariaDB stores:

- Users
- Posts
- Pages
- Comments
- Settings
- Plugins configuration

## Configuration

```ini
bind-address = 0.0.0.0
```

Allows other containers to connect.

```ini
datadir = /var/lib/mysql
```

Location of database files.

## Startup Script

On first start:

1. Check if database exists.
2. Start MariaDB temporarily.
3. Create database.
4. Create user.
5. Grant privileges.
6. Set root password.
7. Stop temporary server.
8. Start MariaDB in foreground.

---

# WordPress / PHP-FPM

Packages installed:

- php-fpm
- php-mysql
- curl
- wget
- WP-CLI

## php-mysql

`php-mysql` is the PHP extension that allows PHP to communicate with MariaDB.

```text
PHP
 │
 ▼
php-mysql
 │
 ▼
SQL Queries
 │
 ▼
MariaDB
```

## WP-CLI

- `wp core download` → Downloads WordPress.
- `wp config create` → Creates `wp-config.php`.
- `wp core install` → Creates database tables and admin account.
- `wp user create` → Creates additional users.

## PHP-FPM Configuration

```ini
listen = 9000
```

Allows NGINX to communicate over TCP.

```ini
pm = dynamic
```

Dynamic worker management.

```ini
pm.max_children = 5
```

Maximum PHP workers.

```ini
clear_env = no
```

Allows PHP to access Docker environment variables.

## Initialization

First startup:

1. Create `/run/php`
2. Download WordPress
3. Wait for MariaDB
4. Generate `wp-config.php`
5. Install WordPress
6. Create admin
7. Create secondary user
8. Start PHP-FPM

---

# WordPress Architecture

```text
/var/www/html
│
├── index.php
├── wp-config.php
├── wp-admin/
├── wp-content/
└── wp-includes/
```

## index.php

Entry point of WordPress.

## wp-config.php

Stores:

- Database credentials
- Security keys
- Table prefix
- Debug configuration

## wp-admin

Administration dashboard.

## wp-content

Contains:

- themes/
- plugins/
- uploads/

## wp-includes

Contains WordPress core libraries.

---

# WordPress Request Lifecycle

```text
Browser
    │
HTTP Request
    │
    ▼
NGINX
    │
FastCGI
    │
    ▼
PHP-FPM
    │
Execute WordPress
    │
SQL Queries
    │
    ▼
MariaDB
    │
Return Data
    │
    ▼
Generate HTML
    │
    ▼
NGINX
    │
    ▼
Browser
```

---

# WordPress Database

| Table | Purpose |
|--------|---------|
| wp_posts | Posts, pages, attachments, revisions |
| wp_users | Users |
| wp_options | Site settings |
| wp_comments | Comments |
| wp_terms | Categories & tags |
| wp_postmeta | Post metadata |
| wp_usermeta | User metadata |

`wp_posts` stores multiple content types using the `post_type` column:

- post
- page
- attachment
- revision
- custom post types

---

# WordPress Boot Process

```text
index.php
    │
    ▼
wp-blog-header.php
    │
    ▼
wp-load.php
    │
    ▼
wp-config.php
    │
    ▼
wp-settings.php
    │
    ▼
Load Plugins
    │
    ▼
Load Theme
    │
    ▼
Connect to MariaDB
    │
    ▼
Execute SQL Queries
    │
    ▼
Generate HTML
    │
    ▼
Browser
```

---

# Current Progress

## Docker

- [x] Docker Engine
- [x] Docker Compose
- [x] Images
- [x] Containers
- [x] Networks
- [x] Volumes

## MariaDB

- [x] Dockerfile
- [x] Configuration
- [x] Initialization Script
- [x] Persistent Volume

## WordPress

- [x] PHP-FPM
- [x] WP-CLI
- [x] Automatic Installation
- [x] Administrator Creation
- [x] Secondary User Creation
- [x] Custom PHP-FPM Configuration

## Documentation

- [x] Docker Setup
- [x] Docker Compose
- [x] MariaDB
- [x] WordPress
- [x] Request Lifecycle
- [x] Database
- [x] Boot Process


# NGINX

NGINX is the public-facing web server.

- Accepts HTTPS on **443**.
- Terminates SSL/TLS.
- Serves static files.
- Forwards PHP requests to PHP-FPM using FastCGI.

## Why OpenSSL?

OpenSSL is a cryptographic toolkit used to generate public/private keys, certificates, encrypt and decrypt data, create CSRs, and verify certificates.

For the Inception project it is only used to generate a **self-signed TLS certificate** during the image build.

It generates:

| File | Purpose |
|------|---------|
| `inception.key` | Private key kept secret by NGINX. |
| `inception.crt` | Public certificate sent to browsers during the TLS handshake. |

Because the certificate is self-signed, browsers display a security warning, which is expected in this project.
