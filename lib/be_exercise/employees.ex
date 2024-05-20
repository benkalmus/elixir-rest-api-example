defmodule Exercise.Employees do
  @moduledoc """
  The Employees context.
  """

  import Ecto.Query, warn: false
  require Logger
  alias Exercise.Repo
  alias Exercise.Employees.Employee
  alias Exercise.Countries
  alias Exercise.Services.{CurrencyConverter, SimpleCache, SimpleCacheSup}

  @postgres_max_params  65535
  @default_ttl_ms       60_000

  @doc """
  Returns the list of employees.

  ## Examples

      iex> list_employees()
      [%Employee{}, ...]

  """
  def list_employees do
    Repo.all(Employee)
  end

  @doc """
  Gets a single employee.

  Raises `Ecto.NoResultsError` if the Employee does not exist.

  ## Examples

      iex> get_employee!(123)
      %Employee{}

      iex> get_employee!(456)
      ** (Ecto.NoResultsError)

  """
  #get employee and preload country

  def get_employee!(id) do
    Repo.get!(Employee, id)
  end

  @doc """
  Creates a employee.

  ## Examples

      iex> create_employee(%{field: value})
      {:ok, %Employee{}}

      iex> create_employee(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_employee(attrs \\ %{}) do
    %Employee{}
    |> Employee.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a employee.

  ## Examples

      iex> update_employee(employee, %{field: new_value})
      {:ok, %Employee{}}

      iex> update_employee(employee, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_employee(%Employee{} = employee, attrs) do
    employee
    |> Employee.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a employee.

  ## Examples

      iex> delete_employee(employee)
      {:ok, %Employee{}}

      iex> delete_employee(employee)
      {:error, %Ecto.Changeset{}}

  """
  def delete_employee(%Employee{} = employee) do
    Repo.delete(employee)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking employee changes.

  ## Examples

      iex> change_employee(employee)
      %Ecto.Changeset{data: %Employee{}}

  """
  def change_employee(%Employee{} = employee, attrs \\ %{}) do
    Employee.changeset(employee, attrs)
  end

  @doc """
    Batch writes employees to the database.
    Returns two lists, successfully created Employee{} structs and failed Ecto.Changesets{}.

    ## Examples
    iex> batch_write([%Employee{full_name: "John", ...}])
    {:ok, [%Employee{full_name: "John", ...], [] }
  """
  @spec batch_write([%Employee{}]) ::
    {:ok, [] | [%Employee{}], [] | [%Ecto.Changeset{}]}
  def batch_write(employee_attrs) do
    {created_employees, invalid_changesets} = generic_batch_write(employee_attrs, &create_employee/1 )
    {:ok, created_employees, invalid_changesets}
  end

  @doc """
    Batch writes employees to the database using Repo.insert_all as fast as possible.
    NOTE: This operation does not perform validations like Repo.insert, and should be used with caution.
      Intended to be used internally only, e.g seed script.

    Returns a map containing results from the operation.
    %{
      valid_attr: valid_attr,
      invalid_attr: invalid_attr_and_changeset,
      insert_results: insert_results
    }

    valid_attr:  list of attributes passed into the function that returned a valid changeset
    invalid_attr: tuple list of attributes and changesets that returned an invalid changeset,
    insert_results: list of results from Repo.transaction, see up-to-date documentation for exact return errors
  """
  @spec batch_write_unsafe([%Employee{}]) ::
    %{
      valid_attr: [%Employee{}],
      invalid_attr: [{%Employee{}, %Ecto.Changeset{}}],
      insert_results: [{:ok, any()} | {:error, any()}]
    }
  def batch_write_unsafe(employee_attrs) do
    batch_write_unsafe_func(employee_attrs)
  end

  @doc """
  Helper function for preloading Employee and all its associations.
  """
  @spec preload(employee :: %Employee{}) :: %Employee{}
  def preload(employee = %Employee{}) do
    Repo.preload(employee, [:country, country: :currency])
  end

  @doc """
  Returns all employees for a given country id.

  ## Examples

    iex> get_all_by_country_id(1)
    [%Employee{full_name: "John Johnson", country_id: 1, ...}]
  """
  @spec get_all_by_country_id(integer()) :: [%Employee{}] | []
  def get_all_by_country_id(country_id) do
    query =
      from e in Employee,
      where: e.country_id == ^country_id
    Repo.all(query)
  end

  @doc """
  Returns all employees for a given job title.

  ## Examples

    iex> get_all_by_job_title("Developer")
    [%Employee{full_name: "John Johnson", job_title: "Developer", ...}]
  """
  @spec get_all_by_job_title(String.t()) :: [%Employee{}] | []
  def get_all_by_job_title(job_title) do
    query =
      from e in Employee,
      where: e.job_title == ^job_title
    Repo.all(query)
  end

  @doc """
    Returns salary metrics for a given country id, in the currency code of the country given.
    Salary metrics include: min, max, mean average. All values are returned as integers

    ## Examples
    iex> salary_metrics_by_country(1)
    {:ok, %{
      min: 10000,
      max: 20000,
      mean: 15000,
      currency_code: "USD"
    }}
  """
  @spec salary_metrics_by_country(integer()) ::
    {:ok, %{
      min: integer(),
      max: integer(),
      mean: integer(),
      currency_code: String.t()
    }} |
    {:error, :not_found} |
    {:error, :metrics_query_failed}
  def salary_metrics_by_country(country_id) do
    query =
      from e in Employee,
      where: e.country_id == ^country_id,
      select: %{
        min: min(e.salary),
        max: max(e.salary),
        mean: avg(e.salary),
        count: count(e)
      }
    metrics =  Repo.one(query)
    handle_salary_metrics_by_country(metrics, country_id)
  end

  @doc"""
  @spec salary_metrics_by_country(integer()) ::
    {:ok, %{
      min: integer(),
      max: integer(),
      mean: integer(),
      currency_code: String.t()
    }} |
    {:error, :not_found} |
    {:error, :metrics_query_failed}
  """
  @spec salary_metrics_by_country_internal(integer()) ::
  {:ok, %{
    min: integer(),
    max: integer(),
    mean: integer(),
    currency_code: String.t()
  }} |
  {:error, :not_found}
  def salary_metrics_by_country_internal(country_id) do
    case get_all_by_country_id(country_id) do
      [] ->
        {:error, :not_found}

      [head | _tail] = employees ->
        metrics_map = reduce_results_to_metrics(employees)
        code = preload(head).country.currency.code
        result_map = Map.put(metrics_map, :currency_code, code)

        {:ok, result_map}
    end
  end

  @doc """
    Returns salary metrics for a given job title, in the currency code of the country given.
    Salary metrics include: min, max, mean average. All values are returned as integers and are rounded up.

    ## Examples
    iex> salary_metrics_by_job_title("Developer")
    {:ok, %{
      min: 10000,
      max: 20000,
      mean: 15000,
      currency_code: "USD"
    }}
  """
  @spec salary_metrics_by_job_title(String.t()) ::
  {:ok, %{
    min: integer(),
    max: integer(),
    mean: integer(),
    currency_code: String.t()
  }} |
  {:error, :not_found}
  def salary_metrics_by_job_title(job_title, target_currency \\ "USD") do
    query =
      from e in Employee,
      join: country in Exercise.Countries.Country, on: country.id == e.country_id,
      join: currency in Exercise.Countries.Currency, on: country.currency_id == currency.id,
      where: e.job_title == ^job_title,
      preload: [country: {country, currency:  currency}],
      select: %{
        employee: e,
        salary: e.salary,
        currency: currency.code
      }

    result = Repo.all(query)
    handle_job_title_metrics(result, target_currency)
  end

  ## ==================================================================
  ## API with Caching

  @doc """
    Cached version of handle_salary_metrics_by_country/1.
    Attempts to retrieve a cached result, if not found, queries the DB, stores a new cache and returns the result.
  """
  def salary_metrics_by_country_cached(country_id) do
    case SimpleCache.get(SimpleCacheSup.employee_metrics_cache(), country_id) do
      {:ok, result} ->
        {:ok, result}
      {:error, _} ->
        result = salary_metrics_by_country(country_id)
        SimpleCache.insert(SimpleCacheSup.employee_metrics_cache(), country_id, result, @default_ttl_ms)
        result
    end
  end

  ## ==================================================================
  ## Internal functions

  ## Takes a list of attributes to insert to Database, in concurrent batches.
  ## This functions takes an insert function, such as Employee.create_employee/1, and runs it concurrently using
  ## maximum number of DB connections configured by :pool_size.
  ## The higher order function is required to return output from Repo.insert, ie: {:ok, result} or {:error, changeset}
  ## Returns a list of inserted structs and a tuple list of failed attributes with their changesets.
  @spec generic_batch_write([map()], (map() -> {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}) )
    :: {[map()], [{map(), Ecto.Changeset.t()}]}
  defp generic_batch_write(attr_list, create_fun) do
    #number of async workers should match to number of DB connections. Defaults to 10.
    pool_size = Application.get_env(:be_exercise, Repo)[:pool_size] || 10

    {valid_structs, invalid_changesets} =
      attr_list
      |> Task.async_stream(fn attr ->
          case create_fun.(attr) do
            {:ok, struct} -> {:ok, struct}
            # on failure, return the attributes and changeset
            {:error, changeset} -> {attr, changeset}
          end
        end, max_concurrency: pool_size, on_timeout: :kill_task)
      # separate results into two lists: inserted structs and failed changesets
      |> Enum.reduce({[],[]}, &reduce_employee_schema_results/2)

    {valid_structs, invalid_changesets}
  end

  # Helper function for performing batch_write unsafely (without validation). Intended to be used internally only.
  defp batch_write_unsafe_func(attr_list) do
    # insert_all doesn't autogenerate timestamps, generate them ourselves.
    #Add timestamps as placeholders
    date_placeholders = %{
      inserted_at: {:placeholder, :datetime},
      updated_at: {:placeholder, :datetime}
    }

    # perform changeset validation concurrently, note that this won't check constraints such as foreign id key checks
    # (as this is done on Repo.insert)
    {valid_attr, invalid_attr_and_changeset} =
      attr_list
      |> Task.async_stream(fn attr ->
        c = Employee.changeset(%Employee{}, attr)

        new_attr = Enum.into(date_placeholders, attr)
        case c.valid? do
          true -> {:ok, new_attr}
          false -> {:error, {attr, c}}
        end
      end, max_concurrency: System.schedulers_online(), on_timeout: :kill_task)

      |> Enum.reduce({[],[]}, &reduce_employee_schema_results/2)

    insert_results = insert_all_in_batches(valid_attr)
    ## instead of handling transaction results, allow the caller to handle and interpret the results

    %{
      valid_attr: valid_attr,
      invalid_attr: invalid_attr_and_changeset,
      insert_results: insert_results
    }
  end

  defp insert_all_in_batches(attributes) do
    # generate datetime for timestamps suitable for PostgreSQL DB
    datetime = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

    # DB can refuse insert if chunks are too large
    # limit number of params to max possible: 65535 / (parameters per attribute)
    # div() rounds down and returns an integer
    chunks =  div @postgres_max_params, Enum.count(hd(attributes))

    attributes
    |> Enum.chunk_every(chunks)
    |> Enum.reduce([], fn chunk, acc ->
      transaction_result = Repo.transaction(fn ->
        Repo.insert_all(Employee, chunk,
          # insert_all options:
          placeholders: %{datetime: datetime},  #replace placeholders with datetime
          on_conflict: :nothing   # skip if already exists
        )
      end)
      [transaction_result | acc]
    end)
  end

  defp handle_salary_metrics_by_country(%{count: num} = query_result, country_id) when num > 0 do
    currency_code =   #todo, find out if we can retrieve currency_code in one query
      Countries.preload(Countries.get_country!(country_id)).currency.code

    # PostgreSQL uses Decimal to calculate average, convert back to integer and update map
    mean_int = Decimal.to_integer(Decimal.round(query_result.mean, 0))
    # update mean with an integer
    query_result = %{query_result | mean: mean_int }

    # add currency code to result map
    result = Map.put(query_result, :currency_code, currency_code)
    {:ok, result}
  end
  #if count == 0, the query did not find employees for given country
  defp handle_salary_metrics_by_country(%{count: 0} = _query_result, _country_id) do
    {:error, :not_found}
  end
  #query failed
  defp handle_salary_metrics_by_country(query_result, _) do
    Logger.error("Salary metrics by country query failed to produce metrics in #{inspect query_result}")
    {:error, :metrics_query_failed}
  end


  defp handle_job_title_metrics([], _target_currency) do
    {:error, :not_found}
  end
  defp handle_job_title_metrics([head | tail] = query_results, target_currency) do
    {min, max, sum}  =
      tail
      #use first elem as intial Enum acc values
      |> Enum.reduce({head.employee.salary, head.employee.salary, head.employee.salary},  #TODO this reduce function is used twice, refactor generic
        fn map, {min, max, sum} ->
          salary = map.employee.salary
          currency = map.currency
          {:ok, salary_converted} = CurrencyConverter.convert(currency, target_currency, salary)
          {
            # if left hand side = `true`, returns min/max. If left hand side = `false`, return || salary_converted
            min < salary_converted && min || salary_converted,
            max > salary_converted && max || salary_converted,
            sum + salary_converted
          }
        end)

    mean = sum / Enum.count(query_results)

    {:ok, %{
      min: round(min),
      max: round(max),
      mean: round(mean),
      currency_code: target_currency
    }}
  end

  defp reduce_employee_schema_results({:ok, {:ok, struct}}, {successes, failures}) do
    {[struct | successes], failures}
  end
  defp reduce_employee_schema_results({:ok, {_attr, _changeset} = r}, {successes, failures}) do
    {successes, [r | failures]};
  end
  defp reduce_employee_schema_results(_, acc) do
    acc
  end

  defp reduce_results_to_metrics([head | tail] = input_employees) do
    {min, max, sum} =
      tail
      #use first elem as intial accumulator values
      |> Enum.reduce({head.salary, head.salary, head.salary}, &reduce_results_to_metrics_func/2)

    mean = round(sum / Enum.count(input_employees))
    %{
      min: min,
      max: max,
      mean: mean
    }
  end

  defp reduce_results_to_metrics_func(employee, {min, max, sum}) do
    salary = employee.salary
    {
      # if left hand side = `true`, returns left hand side -> min/max. If left hand side = `false`, return right hand side -> salary
      min < salary && min || salary,
      max > salary && max || salary,
      sum + salary
    }
  end

end
