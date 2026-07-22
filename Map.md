## Linux Operating System Fundamentals
* Process Management (PID 1, Daemons, Signals)
* File Security (Users, Permissions)

⬇️

## Containerization Primitives
* Isolation (Namespaces, cgroups)
* Storage (OverlayFS, Copy-on-write)

⬇️

## Docker Architecture
* Docker Engine (Daemon, Client, Images)
* Dockerfile Mechanics (ENTRYPOINT, RUN, CMD)

⬇️

## Docker Compose (Orchestration)
* Secrets Management (.env)
* Volume Persistence (Bind Mounts)
* Internal Networking (Bridge, Docker DNS)

⬇️

## The Inception Application Stack
* **NGINX** (Reverse Proxy, Event Loop, Port 443, TLS 1.3)
  * ↳ *FastCGI Protocol (Over internal Docker network)*
* **PHP-FPM / WordPress** (Logic Execution, WP-CLI, wp-config.php)
  * ↳ *SQL Queries (Over internal Docker network)*
* **MariaDB** (Relational Data, Privileges, Isolated Port 3306)