# Variables
COMPOSE_FILE = ./srcs/docker-compose.yml
DATA_PATH = /home/ykhoussi/data

# Default rule to build and launch everything
all:
	@echo "Building and starting the Inception infrastructure..."
	@mkdir -p $(DATA_PATH)/mariadb
	@mkdir -p $(DATA_PATH)/wordpress
	docker-compose -f $(COMPOSE_FILE) up -d --build

# Stop the containers
down:
	@echo "Stopping the containers..."
	docker-compose -f $(COMPOSE_FILE) down

# Stop and completely remove containers, networks, and images
clean: down
	@echo "Cleaning up Docker environment..."
	docker system prune -af

# Deep clean: remove everything including the permanent volumes and their data
fclean: clean
	@echo "Performing deep clean and deleting volume data..."
	docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	sudo rm -rf $(DATA_PATH)/mariadb/*
	sudo rm -rf $(DATA_PATH)/wordpress/*

# Rebuild everything from scratch
re: fclean all

.PHONY: all down clean fclean re