defmodule Exercise.Employees do
  @moduledoc """
  The Employees context.
  """

  import Ecto.Query, warn: false
  require Logger
  alias Exercise.Repo

  alias Exercise.Employees.Employee

  @doc """
  Returns the list of employees.

  ## Examples

      iex> list_employees()
      [%Employee{}, ...]

  """
  def list_employees do
    Repo.all(Employee)
    |> Repo.preload(:country)
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
    |> Repo.preload(:country)
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
    Returns two lists, successful employee creations and failed changesets.

    {:ok, [%Employee{}], [%Ecto.Changeset{}] }
  """
  #TODO clean this up
  def batch_write(employee_attrs) do
    # drive this via config, but not pool_size
    pool_size = Application.get_env(:be_exercise, Repo)[:pool_size] || 10
    datetime = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
    dates = %{
      inserted_at: datetime,
      updated_at: datetime
    }
    {successful, failed} =
      employee_attrs
      |> Task.async_stream(fn attr ->
        c = Employee.changeset(%Employee{}, attr)

        new_attr = dates |> Enum.into(attr)
        case c.valid? do
          true -> {:ok, new_attr} #Repo.insert(c)
          false -> {:error, c}
        end
      end, max_concurrency: pool_size)
      |> Enum.reduce({[],[]},
        fn {:ok, {:ok, success}}, {s, f} ->
          {[success|s], f};
        failed, {s, f} ->
          {s, [failed|f]}
        end)

    successful
    |> Enum.chunk_every(10000)
    |> Enum.each( fn chunk ->
      Repo.transaction(fn ->
        Repo.insert_all(Employee, chunk)
      end)
    end)


    # IO.inspect(pool_size)
    {:ok, successful, failed}
  end
end
