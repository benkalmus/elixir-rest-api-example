defmodule ExerciseWeb.EmployeeView do
  use ExerciseWeb, :view
  alias Exercise.Employees.Employee

  @doc """
  Renders a list of employees.
  """
  def index(%{employees: employees}) do
    %{data: for(employee <- employees, do: data(employee))}
  end

  @doc """
  Renders a single employee.
  """
  def show(%{employee: employee}) do
    %{data: data(employee)}
  end

  @doc """
  Renders a batched insert results into successful and failed lists.
  ## TODO Example
  """
  def batch_result(%{successful: successful, failed: failed}) do
    errors = Enum.map(failed, fn {attr, changeset} ->
      error = Ecto.Changeset.traverse_errors(changeset, &ExerciseWeb.ErrorHelpers.translate_error/1)
      %{
        params: attr,
        error: error
      }
    end)

    render_successful =
      successful
      |> Exercise.Repo.preload(:country)  #preload for country.id
      |> Enum.map(&data/1)

    %{successful: render_successful, failed: errors}
  end

  defp data(%Employee{} = employee) do
    %{
      id: employee.id,
      full_name: employee.full_name,
      job_title: employee.job_title,
      salary: employee.salary,
      country_id: employee.country.id
    }
  end
end
