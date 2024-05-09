include vsn.mk

PROJECT_NAME="chat_app"

# TODO commands:
# start pheonix server
# run migrations 
# run seed script
# benchmark

# show help/usage

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
	mix phx.server

.PHONEY: db-down
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