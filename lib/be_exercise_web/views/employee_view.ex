defmodule ExerciseWeb.EmployeeView do
  use ExerciseWeb, :view
  alias Exercise.Employees
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
      |> Enum.map(&data/1)

    %{successful: render_successful, failed: errors}
  end

  def display_metrics(%{min: min, max: max, mean: mean, currency_code: code}) do
    %{
      min: min,
      max: max,
      mean: mean,
      currency_code: code,
    }
  end

  ## ====================================================================
  ## Internal Functions

  defp data(%Employee{} = employee) do
    employee = Employees.preload(employee)
    %{
      id: employee.id,
      full_name: employee.full_name,
      job_title: employee.job_title,
      salary: employee.salary,
      country_id: employee.country.id,
      country_name: employee.country.name,
      currency_code: employee.country.currency.code
    }
  end
end
