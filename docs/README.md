# Documentation

For posterity, the following diagram displays a basic overview of the be-exercise app below.

![image](diagrams/svg/be-code-exercise-initial.svg)

The application exposes simple CRUD API for `Currency` and `Country` tables in a PostgreSQL Database. 
It follows the architecture of a standard, generated phoenix project. 
`Currencies` and `Countries` are related via a one-to-many relationship. 

## Reqs
- Fix existing bugs in the application
- Create an employee resource
- Seed script
- Salary metrics endpoint

### TODOs

- [x] Organise repo directory structure:
  - add `priv/docker` dir for storing docker compose files used to launch databses
  - add `docs` and other documentation subdirs containing READMEs, plantuml and generated svg diagrams

- [x] Changelog and version tracking

- [x] Setup docker compose files

- [x] Makefile for easy startup and teardown of containers, tests and app

- [] Environment file: move credentials out of configs and into .env files

- [] Separate seeding functionality for maintainability of seeds.exs

- [] **Testing**
  - [] expand current solution test coverage
  - [] Employees table
  - [] 

- [] **Metrics** endpoints
  - [] fetch salary stats given country (min, max, mean)
  - [] fetch salary stats given job title (mean)

- [] **Benchmarking**. 
  - [] How does it scale under increasing vars such as Num Records in DB, concurrent connections...
  - [] inserts
  - [] reads
  - [] fetch stats endpoint

- [] **Load** testing using (hey)[https://github.com/rakyll/hey]

- [] **Documentation**. Ensure @spec and doc comments are provided on all API (with examples where relevant)
  - [x] Generate initial app diagram
  - [] Diagrams: generate sequence diagrams for API

## Exploring optimizations and Design decisions

- batched inserts 
  - should help seed database quickly

- **Employee** table: Consider DB relationship between Employees and Countries. https://hexdocs.pm/ecto/associations.html 
  - Country (one to many) Employee
  - What data type should I use to store salaries. Consider deps: https://hexdocs.pm/money/readme.html#full-list
  - What options are there to optimise queries on fetching employees given country, or title.

- **Metrics endpoints**:
  - per_country_salary(country) -> {currency_code_, average, min, max}
    - 
  - per_title_salary(job_title, currency // "USD") -> average
    - currency conversion!

- **Metrics cache**: 
- Employee metrics record is currently the only place this app is going to do **work** (calculations). Therefore we should store this work in a cache for faster retrieval
  - In-memory Cache options: 
    - **ETS**. 
    - Gen servers & state
  - Consider ways to **invalidate** the cache.
    - Time expiry. Can cause served data to be stale
    - Event listener / monitor that will invalidate cache if e.g. new employee has been added. 
      - what if another application makes changes to the DB? should I assume that only this app can alter DB? 
        - Manually invalidate cache on writes. Pubsub mechanism & Gen server pool
        - postgresql notify 


- Add logic to seed 10,000 employees into the DB. They key will be to make it fast


## Future considerations
- **Distributed sys**: 
  - Reasons to make a distributed application:
    - Future metrics endpoints might be work heavy
      - metrics work can be load balanced and distributed among nodes, then results stored in a shared cache. 
    - 
  - Reasons not to:
    - simple CRUD API, an interface to DB won't benefit from multiple nodes. Read and write limited by DB
    - increased complexity
      - should break up the app into smaller microservices: 
        - CRUD API, Metrics workers, Key-Value cache

  - distributed key-value store as cache instead of ETS (local only)
  - third party service such as redis, varnish

- Cache layer for reads

- CRQ pattern 
