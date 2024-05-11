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

- [] Schemas
  - inspect Country - Currency relationship schema
    - Country belongs_to currencies
    - Currency has_many countries
  - Index fields
    - specific fields only. Faster WHERE queries. 
    - currency code unique
    - country code unique

- [] Add logic to seed 10,000 employees into the DB. The key will be to make it fast
  - [] Separate seeding functionality for maintainability of seeds.exs

- [] Improve application logging 

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
  - Most importantly, what currency should I store the salary field as?
    * 1) Currency local to the Employee's country
      - Convert currency on READ. 
      - **Pros**:
        - Logical solution: currency is already stored in the Currency table by association.
        - No need to convert salary back into Employee's local currency, which can change based on the conversion rate. 
      - **Cons**: 
        - Must convert salary to a common currency on metrics endpoint, which will slow down aggregates. 
    * 2) Common currency, such as USD for all Employees.
      - **Pros**: 
        - Simpler and faster aggregates (min, max, avg and other future) calculations
      - **Cons**: 
        - Must convert employee salaries on every WRITE. 
        - Potential Inconsistency: e.g. If two employees are being hired at the same salary but the currency conversion rate changes in between DB WRITEs, then one employee will be paid slightly less while the other slightly more! This can be resolved by storing historical currency changes but increases complexity. 
    * **Decision**: The answer depends entirely on the purpose of this application. If performance of the metrics endpoint is the ultimate concern then converting salaries on writes will be more suitable, especially if this application will reach an external Currency conversion service in the future. However this comes at a cost, as mentioned above, and so for data accuracy and consistency reasons I decide to store Employee Salaries in their local currency. 

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

- CQRS pattern: separate read and write operations

