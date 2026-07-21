name = inception

# Variables for cleaner commands
LOGIN	= ykhoussi
DATA	= /home/$(LOGIN)/data
COMPOSE	= docker-compose -f ./srcs/docker-compose.yml	

all: 
	@echo "Building and starting containers..."
	@sudo mkdir -p $(DATA)/mariadb
	@sudo mkdir -p $(DATA)/wordpress
	$(COMPOSE) up -d --build

down:
	@echo "Stopping containers..."
	$(COMPOSE) down

clean: down
	@echo "Cleaning up Docker environment..."
	docker system prune -a -f

fclean: clean
	@echo "Deep cleaning volumes and data..."
	docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	sudo rm -rf $(DATA)/mariadb/*
	sudo rm -rf $(DATA)/wordpress/*

re: fclean all

.PHONY: all down clean fclean re