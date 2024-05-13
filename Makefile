include vsn.mk

PROJECT_NAME="chat_app"

# TODO commands:
# run migrations 
# run seed script
# benchmark
# show help/usage

# ==============================
# App

# Run phoenix app
.PHONY: server
server: db-up
	mix phx.server

# Run phoenix app with REPL shell
.PHONY: shell
shell: db-up
	iex -S mix 

# ==============================
# DB

# Creates DB and runs migrations only
.PHONY: db-setup
db-setup: db-up
	mix ecto.create
	mix ecto.migrate
	make docker-stop 

# Removes everything in DB, then creates it, runs migrations and runs seed script
.PHONY: db-reset
db-reset: db-up
	@read -p "Are you sure you want to recreate DB? [y/n]" response;\
	if [ "$$response" = "y" ]; then\
		mix ecto.reset;\
	fi
	make docker-stop 

# Removes everything in the DB
.PHONY: db-drop
db-drop: db-up
	@read -p "Are you sure you want to drop DB? [y/n]" response;\
	if [ "$$response" = "y" ]; then\
		mix ecto.drop;\
	fi
	make docker-stop 

# ==============================
# Testing 

# Stops all containers that could interfere, then starts test DB and runs `mix test`. Container is stopped after tests 
.PHONY: test
test: docker-stop
	docker compose -f priv/docker/docker-compose-test.yml up -d && sleep 1; \
	mix test || true
	docker compose -f priv/docker/docker-compose-test.yml down

# ==============================
# Docker Containers
.PHONY: db-up
db-up:
	docker compose -f priv/docker/docker-compose-dev.yml up -d


.PHONY: db-down
db-down:
	docker compose -f priv/docker/docker-compose-dev.yml down

.PHONY: docker-stop
docker-stop:
	@CONTAINERS=$$(docker ps --filter name=be-exercise-postgres --filter status=running -q ); \
	if [ -n "$$CONTAINERS" ]; then echo "Killing exercise containers"; docker stop $$CONTAINERS; fi

# ==============================
# Misc
.PHONY: version
version:
	@echo $(PROJECT_VERSION)