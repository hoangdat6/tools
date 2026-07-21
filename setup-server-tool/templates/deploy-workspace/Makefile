SHELL := /bin/bash

INFRA_ROOT := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
-include $(INFRA_ROOT)/env/deploy.env

DOCKER_COMPOSE ?= docker compose
SOURCES_ROOT ?= $(HOME)/sources
DEPLOY_ROOT ?= $(HOME)/deploy
BACKEND_DIR ?= $(SOURCES_ROOT)/backend
FRONTEND_IMAGE_ARCHIVE ?= $(DEPLOY_ROOT)/frontend.tar.gz
APP_COMPOSE_FILE ?= $(INFRA_ROOT)/compose.yml
BACKEND_COMPOSE_FILE ?= $(BACKEND_DIR)/docker-compose.yaml
NPM_COMPOSE_FILE ?= $(INFRA_ROOT)/nginx-proxy-manager/compose.yml
BACKEND_ENV_FILE ?= $(INFRA_ROOT)/env/.env.be
FRONTEND_SERVICE ?= frontend
BACKEND_APP_SERVICE ?= recruit-app
BACKEND_DEPLOY_SCRIPT ?= ./scripts/dev.deploy.sh
BACKEND_READY_WAIT ?= 5

.PHONY: help fe be all build up down restart restart-all clean logs logs-fe logs-be logs-npm status check-app-compose check-backend

help:
	@echo "Available targets:"
	@echo "  make fe          - Load and deploy the frontend image"
	@echo "  make be          - Deploy backend and run its deploy script"
	@echo "  make all         - Deploy frontend and backend"
	@echo "  make build       - Build frontend and backend Compose services"
	@echo "  make up          - Start frontend and backend services"
	@echo "  make down        - Stop frontend and backend services"
	@echo "  make restart     - Restart frontend and backend services"
	@echo "  make clean       - Remove app containers, volumes, and local images"
	@echo "  make logs        - Follow frontend Compose logs"
	@echo "  make logs-fe     - Follow frontend service logs"
	@echo "  make logs-be     - Follow backend Compose logs"
	@echo "  make logs-npm    - Follow Nginx Proxy Manager logs"
	@echo "  make status      - Show app, backend, and proxy status"

check-app-compose:
	@test -f "$(APP_COMPOSE_FILE)" || { echo "Missing $(APP_COMPOSE_FILE). Start from compose.yml.example." >&2; exit 1; }

check-backend:
	@test -d "$(BACKEND_DIR)" || { echo "Missing backend source: $(BACKEND_DIR)" >&2; exit 1; }
	@test -f "$(BACKEND_COMPOSE_FILE)" || { echo "Missing backend Compose file: $(BACKEND_COMPOSE_FILE)" >&2; exit 1; }
	@test -f "$(BACKEND_ENV_FILE)" || { echo "Missing backend env file: $(BACKEND_ENV_FILE)" >&2; exit 1; }

fe: check-app-compose
	@echo "===== Deploying frontend ====="
	@test -f "$(FRONTEND_IMAGE_ARCHIVE)" || { echo "Missing image archive: $(FRONTEND_IMAGE_ARCHIVE)" >&2; exit 1; }
	docker load -i "$(FRONTEND_IMAGE_ARCHIVE)"
	$(DOCKER_COMPOSE) -f "$(APP_COMPOSE_FILE)" up -d "$(FRONTEND_SERVICE)"

be: check-backend
	@echo "===== Deploying backend ====="
	cp "$(BACKEND_ENV_FILE)" "$(BACKEND_DIR)/.env"
	$(DOCKER_COMPOSE) -f "$(BACKEND_COMPOSE_FILE)" up -d
	@echo "Waiting $(BACKEND_READY_WAIT)s for backend services..."
	sleep "$(BACKEND_READY_WAIT)"
	$(DOCKER_COMPOSE) -f "$(BACKEND_COMPOSE_FILE)" exec -T "$(BACKEND_APP_SERVICE)" bash -lc 'chmod +x "$(BACKEND_DEPLOY_SCRIPT)" && "$(BACKEND_DEPLOY_SCRIPT)"'
	sudo chown -R "$${USER}:$$(id -gn)" "$(BACKEND_DIR)"

all: fe be

build: check-app-compose check-backend
	$(DOCKER_COMPOSE) -f "$(APP_COMPOSE_FILE)" build
	$(DOCKER_COMPOSE) -f "$(BACKEND_COMPOSE_FILE)" build

up: check-app-compose check-backend
	$(DOCKER_COMPOSE) -f "$(APP_COMPOSE_FILE)" up -d
	$(DOCKER_COMPOSE) -f "$(BACKEND_COMPOSE_FILE)" up -d

down: check-app-compose check-backend
	$(DOCKER_COMPOSE) -f "$(BACKEND_COMPOSE_FILE)" down
	$(DOCKER_COMPOSE) -f "$(APP_COMPOSE_FILE)" down

restart restart-all: check-app-compose check-backend
	$(DOCKER_COMPOSE) -f "$(APP_COMPOSE_FILE)" restart
	$(DOCKER_COMPOSE) -f "$(BACKEND_COMPOSE_FILE)" restart
	@sleep "$(BACKEND_READY_WAIT)"
	$(DOCKER_COMPOSE) -f "$(BACKEND_COMPOSE_FILE)" exec -T "$(BACKEND_APP_SERVICE)" bash -lc 'chmod +x "$(BACKEND_DEPLOY_SCRIPT)" && "$(BACKEND_DEPLOY_SCRIPT)"'
	sudo chown -R "$${USER}:$$(id -gn)" "$(BACKEND_DIR)"

clean: check-app-compose check-backend
	$(DOCKER_COMPOSE) -f "$(BACKEND_COMPOSE_FILE)" down -v --rmi local
	$(DOCKER_COMPOSE) -f "$(APP_COMPOSE_FILE)" down -v --rmi local

logs: check-app-compose
	$(DOCKER_COMPOSE) -f "$(APP_COMPOSE_FILE)" logs -f

logs-fe: check-app-compose
	$(DOCKER_COMPOSE) -f "$(APP_COMPOSE_FILE)" logs -f "$(FRONTEND_SERVICE)"

logs-be: check-backend
	$(DOCKER_COMPOSE) -f "$(BACKEND_COMPOSE_FILE)" logs -f

logs-npm:
	@test -f "$(NPM_COMPOSE_FILE)" || { echo "Missing NPM Compose file: $(NPM_COMPOSE_FILE)" >&2; exit 1; }
	$(DOCKER_COMPOSE) -f "$(NPM_COMPOSE_FILE)" logs -f

status:
	@test ! -f "$(APP_COMPOSE_FILE)" || $(DOCKER_COMPOSE) -f "$(APP_COMPOSE_FILE)" ps
	@test ! -f "$(BACKEND_COMPOSE_FILE)" || $(DOCKER_COMPOSE) -f "$(BACKEND_COMPOSE_FILE)" ps
	@test ! -f "$(NPM_COMPOSE_FILE)" || $(DOCKER_COMPOSE) -f "$(NPM_COMPOSE_FILE)" ps
