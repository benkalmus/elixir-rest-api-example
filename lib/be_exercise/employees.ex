defmodule Exercise.Employees do
  @moduledoc """
  The Employees context.
  """

  import Ecto.Query, warn: false
  require Logger
  alias Exercise.Repo
  alias Exercise.Employees.Employee
  alias Exercise.Countries

  @postgres_max_params 65535
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
    Batch writes employees to the database using Repo.insert_all.
    NOTE: This operation does not perform validations like Repo.insert, and should be used with caution.

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
  @spec batch_write_unsafe(%Employee{}) ::
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
    Salary metrics include: min, max, mean average.

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
    }}
    | {:error, :not_found}
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
    case Repo.one(query) do
      nil ->
        {:error, :not_found}
      metrics ->
        currency_code =
          Countries.preload(Countries.get_country!(country_id)).currency.code

        # PostgreSQL uses Decimal to calculate average, convert back to integer and update map
        mean_int = Decimal.to_integer(Decimal.round(metrics[:mean], 0))
        metrics = %{metrics | mean: mean_int }
        result = Map.put(metrics, :currency_code, currency_code)
        {:ok, result}
    end
  end

  ## TODO benchmark performance vs DB query
  def salary_metrics_by_country_internal(country_id) do
    case get_all_by_country_id(country_id) do
      [] ->
        {:error, :not_found}

      [head | tail] = employees ->
        {min, max, sum} = tail
          #use first elem as intial Enum acc values
          |> Enum.reduce({head.salary, head.salary, head.salary},
          fn e, {min, max, sum} ->
            salary = e.salary
            {
              # if left hand side = `true`, returns min/max. If left hand side = `false`, return || salary
              min < salary && min || salary,
              max > salary && max || salary,
              sum + salary
            }
          end)

        mean = sum / Enum.count(employees)
        code = preload(head).country.currency.code

        {:ok, %{
          min: min,
          max: max,
          mean: mean,
          currency_code: code
        }}
    end
  end


  def salary_metrics_by_job_title(job_title, target_currency \\ "USD") do
    query =
      from e in Employee,
      # join: country in assoc(e, :country),
      join: country in Exercise.Countries.Country, on: country.id == e.country_id,
      join: currency in Exercise.Countries.Currency, on: country.currency_id == currency.id,
      # join: currency in assoc(country :currency),
      where: e.job_title == ^job_title,
      preload: [country: {country, currency:  currency}],
      select: %{
        employee: e,
        currency: currency.code
      }

    result = Repo.all(query)

    final  =
      result
      #use first elem as intial Enum acc values
      |> Enum.reduce({nil, nil, 0},
      fn e, {min, max, sum} ->
        salary = e[:employee].salary
        currency = e[:currency]
        {:ok, salary_usd} = Exercise.Services.CurrencyConverter.convert(currency, target_currency, salary)
        {
          # if left hand side = `true`, returns min/max. If left hand side = `false`, return || salary
          min && min < salary_usd && min || salary_usd,
          max && max > salary_usd && max || salary_usd,
          sum + salary_usd
        }
      end)
    {min, max, sum} = final
    mean = round(sum / Enum.count(result))

    {:ok, %{
      min: round(min),
      max: round(max),
      mean: round(mean),
      currency_code: target_currency
    }}
  end

  ## ==================================================================
  ## Internal functions

  ## Performs a concurrency write on a list of attributes using a given function to insert to DB.
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
          placeholders: %{datetime: datetime},
          on_conflict: :nothing   # skip if already exists
        )
      end)
      [transaction_result | acc]
    end)
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

end
