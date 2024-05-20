include vsn.mk

.PHONY: server shell deps help db-setup db-seed db-reset db-drop test test-one db-up db-down docker-stop version

PROJECT_NAME="be_exercise"

# ==============================
# App

# Run phoenix app
server: db-up
	mix phx.server

# Run phoenix app with REPL shell
shell: db-up
	iex -S mix 

# Fetches deps defined in mix.exs
deps:
	mix deps.get

help: 
	@echo "Commands:"
	@echo "server, shell, db-setup, db-seed, db-reset, db-drop, test, test-one, version"

# ==============================
# DB

# Creates DB and runs migrations only
db-setup: db-up
	mix ecto.create
	mix ecto.migrate
	$(MAKE) docker-stop 

# Creates DB, migrates and runs seed script
db-seed: db-up
	mix seed
	$(MAKE) docker-stop 

# Removes everything in DB, then creates it, runs migrations and runs seed script
db-reset: db-up
	@read -p "Are you sure you want to recreate DB? [y/n]" response;\
	if [ "$$response" = "y" ]; then\
		mix reset;\
	fi
	$(MAKE) docker-stop 

# Removes everything in the DB
db-drop: db-up
	@read -p "Are you sure you want to drop DB? [y/n]" response;\
	if [ "$$response" = "y" ]; then\
		mix ecto.drop;\
	fi
	$(MAKE) docker-stop 

# ==============================
# Testing 

# Stops all containers that could interfere, then starts test DB and runs `mix test`. Container is stopped after tests 
test: docker-stop
	docker compose -f priv/docker/docker-compose-test.yml up -d && sleep 1; \
	mix test $(MAKE_TEST_OPTS) || true
	docker compose -f priv/docker/docker-compose-test.yml down

# runs mix test but exits on first error, so we can only see one test failure at a time.
test-one: 
	$(MAKE) MAKE_TEST_OPTS="--max-failures 1" test 


# ==============================
# Benchmarking

bench: db-up 
	mix ecto.drop
	mix seed
	mix run priv/bench/benchmark.exs || true
	$(MAKE) docker-stop

# ==============================
# Docker Containers
db-up:
	docker compose -f priv/docker/docker-compose-dev.yml up -d


db-down:
	docker compose -f priv/docker/docker-compose-dev.yml down

docker-stop:
	@CONTAINERS=$$(docker ps --filter name=be-exercise-postgres --filter status=running -q ); \
	if [ -n "$$CONTAINERS" ]; then echo "Killing exercise containers"; docker stop $$CONTAINERS; fi

# ==============================
# Misc
version:
	@echo $(PROJECT_VERSION)