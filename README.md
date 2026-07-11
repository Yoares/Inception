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

## Setup Status

* [x] Debian 13 VM
* [x] Docker Repository Added
* [x] Docker Engine Installed
* [x] Docker Compose Installed
* [x] Docker Service Running
* [x] User Added to Docker Group
* [ ] Docker Tested Without `sudo`

