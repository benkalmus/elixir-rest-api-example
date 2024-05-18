# Documentation

For posterity, the following diagram displays a basic overview of the be-exercise app below.

![image](diagrams/svg/be-code-exercise-initial.svg)

The application exposes simple CRUD API for `Currency` and `Country` tables in a PostgreSQL Database. 
It follows the architecture of a standard, generated phoenix project. 
`Currencies` and `Countries` are related via a one-to-many relationship. 

## Reqs
- [x] Fix existing bugs in the application
- [x] Create an employee resource
- [x] Seed script
- Salary metrics endpoint

### TODOs

- [x] Organise repo directory structure:
  - add `priv/docker` dir for storing docker compose files used to launch databses
  - add `docs` and other documentation subdirs containing READMEs, plantuml and generated svg diagrams

- [x] Changelog and version tracking

- [x] Setup docker compose files

- [x] Makefile for easy startup and teardown of containers, tests and app

- [] Environment file: move credentials out of configs and into .env files

- [x] Schemas
  - inspect Country - Currency relationship schema
    - [x] Country belongs_to currencies
    - [x] Currency has_many countries
    - [x] Country has_many Employees. Employee belongs_to Country
  - Index fields
    - specific fields only. Faster WHERE queries. 
    - [x] currency code unique
    - [x] country code unique

- [x] **Employee** CRUD
  - [x] Used phoenix generator
    - `mix phx.gen.json Employees Employee employees full_name:string job_title:string salary:integer country:references:countries`
  - [x] add country_id foreign key 
  - [x] Is integer the right type to use for salary?
    - converted to Decimal type
    -  switched back to using an integer for salary, due to growing complexity of the application, currently outside the scope 


- [x] Add logic to seed 10,000 employees into the DB. The key will be to make it fast
  - [x] Separate seeding functionality for maintainability of seeds.exs
  - [x] Concurrent batch_write. Speeds up bullk insert of records

- [] **Logging**  application logging 

- [] **Testing**
  - [] expand current solution test coverage
    - [x] Currency
    - [x] Country
      - [] preload currency
    - [x] Added Data integrity tests to ensure countries and currencies cannot be added twice. 
    - [x] Ensured that records cannot be orphaned when a currency is associated to countries. 
    - [] Ensured that currency foreign key reference cannot be udpated as this will impact meaning of salary field in employee table. 
    - [x] Employee
      - [x] preload
        - update view to show currency in which the salary is paid!
      - [x] query
  - [] 

- [] **Metrics** endpoints
  - [x] fetch salary stats given country (min, max, mean)
  - [] fetch salary stats given job title (mean)

- [] Complete all TODOs

- [] **Benchmarking**. 
  - [] How does it scale under increasing vars such as Num Records in DB, concurrent connections...
  - [] inserts
  - [] reads
  - [] fetch stats endpoint

- [] **Load** testing using (hey)[https://github.com/rakyll/hey]

- [] **Documentation**. Ensure @spec and doc comments are provided on all API (with examples where relevant)
  - [x] Generate initial app diagram
  - [] Diagrams: generate sequence diagrams for API
    - [] Supervision tree and module hierarchy
    - [] DB Model
    - []
  - [] Document API. Usage and possible returns
  - [] seed.exs script usage
    - added help command and module doc

## Exploring optimizations and Design decisions

- Some functions raise exceptions while others do not, such as get_currency! and create_currency(). 
  - refactor API so that functions use one or the other. Raising exceptions stacktrace overhead
    - exceptions in get! is idiomatic elixir. 

- [x] **Resolving deletes** on rows with foreign key references, such as deleting a Currency with a Country reference. 
  Options:
  - allow delete: dangling rows with no foreign key reference will need to be handled in application
  - safe delete: only if all children of parent have been removed and no FK references exist. 
  - **Decided** to go with :restrict option :on_delete. This will prevent orphaning records. 

- [x] **batched inserts** 
  - current insert takes too long to seed database with hundreds of thousands of records
  - add endpoint to batch_write multiple employee records. Options:
    - Pass in collectable and write multiple employees in one request. 
      - return success and failure lists, so that client can fix and retry
    - could expose insert_all for even faster writes, but doesn't perform validation. Should not expose this to web API. 
      - extremely fast writes: 100k inserts in 5sec
    - Parallel pipeline: producer->consumer.
      - employee records -> spawn worker pool: perform changeset validation -> DB writers (match pool_size): Repo.insert 
      - Task.async_stream -> insert_all
  - **solution:**
    - **batch_write**: accepts a list of employee attributes, validates and performs insert. 
      - using Task.async_stream in parallel, with :pool_size number of workers. Easiest, and readable way to spawn worker pool.
    - **batch_write_unsafe**: accepts a list of employee attributes, however, json API is forbidden and only the `seeds.exs` script is allowed to use it. This is because it uses insert_all which doesn't perform any validation.
      - splits input into mini batches as postgresql has a parameter limit 


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
  - [x] per_country_salary(country) -> {currency_code_, average, min, max}
    - Performing min, max and average on the database
  - per_title_salary(job_title, currency // "USD") -> average
    - currency conversion!

- **Metrics cache**: 
- Employee metrics record is currently the only place this app is going to do **work** (calculations). Therefore we should store this work in a cache for faster retrieval
  - In-memory Cache options: 
    - Gen servers & state
  - Consider ways to **invalidate** the cache.
    - Time expiry. Can cause served data to be stale
    - Event listener / monitor that will invalidate cache if e.g. new employee has been added. 
      - what if another application makes changes to the DB? should I assume that only this app can alter DB? 
        - Manually invalidate cache on writes. Pubsub mechanism & Gen server pool
        - postgresql notify 
  - **ETS**:
    - simple cache wrapper around ETS with a supervisor process table owner, simple_cache:start(:employee_salary_metrics)
    - set, public, read_concurrency, true as I expect read bursts and infrequent writes. 
    - something like: {cache_key, {cache_value, insert_datetime}}
    - Employee insert/delete invalidate all Employee cache values

## Future considerations
- **Distributed sys**: 
  - Reasons to make a distributed application:
    - Future metrics endpoints might be work heavy
      - metrics work can be load balanced and distributed among nodes, then results stored in a shared cache. 
    - 
  - Reasons not to:
    - simple CRUD API, an interface to DB won't benefit from multiple nodes. Read and write limited by DB
    - increased complexity
      - should break up the app into smaller microservices. Assign hardware to each app's advantage
        - CRUD API. Lightweight
        - Metrics workers. Faster/More CPUs
        - Key-Value caches. Caches should be given more RAM.

  - Distributed key-value store as cache instead of ETS (local only)
  - third party service such as redis, varnish

- Cache layer for reads

- CQRS pattern: separate read and write operations

- Numeric country and currency codes? 

- Add ease of use API to fetch records via fields such as `name` and `code`. 
  - An example of this already exists in `get_currency_by_code!/1`