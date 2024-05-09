# temporary document tracking todos


# Fixes 
- [x] perform preload only on views, not on API. add comment
  - [x] add preload api 
- tests are sometimes inconsistent! Make sure that it's always expect on left hand side:
  - expected == actual

- add validations on strings


# Todo
- Employee
  - [x] add **currency_code** to all employee views as per requirement. 
  - query to return employees given job_title or country
    [x] country
  - list view for employees that shows currency and salary etc
    - to be used for queries:
      job_title, country
  - first name and last name could be stored separatel

- [x] Use config for Decimal precision after decimalpoint. Currently using 4. I hate magic numbers



- simple cache
  - Supervisor spawns worker (owner of ETS) per each table created. 
    - document: to support dynamic supervisor in future for dynamic cache creation
  - insert(key, cache, time_to_live)
    - upsert logic
    - e.g: (country, {min, max, avg}) {job_title, min, max, avg}
  - expire(key)
    - if Employee created, updated, removed run: 
      - expire(Employee.country), expire(Employee.job_title)
  - get(key)
    - check if key exists,
    - check if ttl expired
    - {ok: value} | {error, :not_found}

    -  periodically check for keys
      - strategies: don't scan whole table at once, batch it. randomize it. maybe use ets:last/prev/next/first

_____________________

# Production Ready notes

- move Employee queries to a separate file
- different changesets for particular operations
- improve input validations, e.g. limit name length 
- there are potential crashes  
- simple cache, should use a better strategy for expiring caches. at the very least, do not iterate on every element in the ETS. 
- add simple cache configs to config file

- **Workflow methodology**
- **Consistency** 
  - in my experience lack of standards, conventions (in other words, consistency) is one of the main issues on big projects
  - write down any assumptions I have to make
  - Proactive communication


- **Performance**
  - Streams instead of Enums 


- **Employee** table
  - Storing Salary as an integer. 
  
- **Ecto/DB tips** 
  - field defaults 


- **Metrics**
  - Document json API

- **CACHE**
  - use Pubsub broadcast whenever an employee was created or updated or deleted, to invalidate cache

- **Monitoring**
  - 

- **Logging** 
  - Configure logger for dev and prod. 

- **Audit Logging**

- Ecto. assocs
  - build_assoc to create new employees
  - put assoc to update employees 

  - running migrations in production 
  - release configuration
  - authentication 

- updating country currency
  - Problems:
    - Changing currency will affect all refernced employee salaries
  - Solutions: 

### Simplify query syntax

consider this instead, looks more readable: 
https://github.com/pentacent/keila/blob/main/lib/keila/accounts/accounts.ex#L52C55-L57C46 
```elixir
  from(a in Account)
  |> join(:inner, [a], g in Auth.Group, on: g.id == a.group_id)
  |> join(:inner, [a, g], ug in Auth.UserGroup, on: ug.group_id == g.id)
  |> join(:inner, [a, g, ug], u in Auth.User, on: u.id == ug.user_id)
  |> where([a, g, ug, u], u.id == ^user_id)
```
