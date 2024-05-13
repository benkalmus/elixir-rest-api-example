defmodule Exercise.Employees do
  @moduledoc """
  The Employees context.
  """

  import Ecto.Query, warn: false
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
  def batch_write(employee_attrs) do
    changesets = Enum.map(employee_attrs, &Employee.changeset(%Employee{}, &1))
    # todo, filter valid? == false changesets

    {successful, failed} =
      Enum.reduce(changesets, {[], []}, fn changeset, {s_acc, f_acc} ->
        case Repo.insert(changeset) do
          {:ok, record} ->
            {[record | s_acc], f_acc}
          {:error, c} ->
            {s_acc, [c | f_acc]}
        end
      end)
    {:ok, successful, failed}
  end
end
