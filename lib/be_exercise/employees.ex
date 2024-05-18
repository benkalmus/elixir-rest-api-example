defmodule Exercise.Employees do
  @moduledoc """
  The Employees context.
  """

  import Ecto.Query, warn: false
  require Logger
  alias Exercise.Repo
  alias Exercise.Employees.Employee
  alias Exercise.Countries

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

    {:ok, [ %Employee{} ], [ %Ecto.Changeset{} ]}
  """
  #TODO, can we make this function generic?
  def batch_write(employee_attrs) do
    #number of async workers should match to number of DB connections. Defaults to 10.
    pool_size = Application.get_env(:be_exercise, Repo)[:pool_size] || 10

    {created_employees, invalid_changesets} =
      employee_attrs
      |> Task.async_stream(fn attr ->
          case create_employee(attr) do
            {:ok, employee} -> employee
            # on failure, return the attributes and changeset
            {:error, changeset} -> {attr, changeset}
          end
        end, max_concurrency: pool_size, on_timeout: :kill_task)
      # separate results into two lists: employees and failed changesets
      |> Enum.reduce({[],[]},
        fn {:ok, {_attr, _changeset} = r}, {successes, failures} ->
          {successes, [r | failures]};
        {:ok, employee}, {successes, failures} ->
          {[employee | successes], failures}
        end)

    {:ok, created_employees, invalid_changesets}
  end

  @doc """
    Batch writes employees to the database using Repo.insert_all.
    NOTE: This operation does not perform validations like Repo.insert, and should be used with caution.

    Returns two lists, successful employee creations and failed changesets.
    {:ok, [employee_attributes :: map()], [%Ecto.Changeset{}] }
  """
  #TODO, can we make this function generic?
  def batch_write_unsafe(employee_attrs) do
    # drive this via config, but not pool_size
    pool_size = Application.get_env(:be_exercise, Repo)[:pool_size] || 10
    # insert_all doesn't autogenerate timestamps, generate them ourselves.
    #Add timestamps as placeholders
    date_placeholders = %{
      inserted_at: {:placeholder, :datetime},
      updated_at: {:placeholder, :datetime}
    }
    # perform changeset validation, note that this won't check constraints (as this is done on Repo.insert)
    {valid_attr, invalid_attr_and_changeset} =
      employee_attrs
      |> Task.async_stream(fn attr ->
        c = Employee.changeset(%Employee{}, attr)

        new_attr = date_placeholders |> Enum.into(attr)
        case c.valid? do
          true -> {:ok, new_attr}
          false -> {:error, {attr, c}}
        end
      end, max_concurrency: pool_size, on_timeout: :kill_task)
      |> Enum.reduce({[],[]},
        fn {:ok, {:ok, success}}, {s, f} ->
          {[success|s], f};
        {:ok, {:error, failed}}, {s, f} ->
          {s, [failed|f]}
        _, acc -> acc     #task failed
        end)

    datetime = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
    valid_attr
    |> Enum.chunk_every(10000) #insert might fail if chunk too large (when number of fields in employee table is high)
    |> Enum.each( fn chunk ->
      Repo.transaction(fn ->
        #todo handle transaction error
        Repo.insert_all(Employee, chunk, placeholders: %{datetime: datetime})
      end)
    end)

    {:ok, valid_attr, invalid_attr_and_changeset}
  end

  @doc """
  Helper function for preloading Employee and all its associations.
  """
  @spec preload(employee :: %Employee{}) :: %Employee{}
  def preload(employee = %Employee{}) do
    Repo.preload(employee, [:country, country: :currency])
  end

  @spec get_all_by_country_id(integer()) :: [%Employee{}] | []
  def get_all_by_country_id(country_id) do
    query =
      from e in Employee,
      where: e.country_id == ^country_id
    Repo.all(query)
  end

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

end
