defmodule Exercise.EmployeesTest do
  use Exercise.DataCase

  alias Exercise.Employees

  describe "employees" do
    alias Exercise.Employees.Employee

    @invalid_attrs %{full_name: nil, job_title: nil, salary: nil}

    test "list_employees/0 returns all employees" do
      employee = employee_fixture()
      assert Employees.list_employees() == [employee]
    end

    test "get_employee!/1 returns the employee with given id" do
      employee = employee_fixture()
      assert Employees.get_employee!(employee.id) == employee
    end

    test "create_employee/1 with valid data creates a employee" do
      valid_attrs = %{full_name: "some full_name", job_title: "some job_title", salary: 42}

      assert {:ok, %Employee{} = employee} = Employees.create_employee(valid_attrs)
      assert employee.full_name == "some full_name"
      assert employee.job_title == "some job_title"
      assert employee.salary == 42
    end

    test "create_employee/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Employees.create_employee(@invalid_attrs)
    end

    test "update_employee/2 with valid data updates the employee" do
      employee = employee_fixture()
      update_attrs = %{full_name: "some updated full_name", job_title: "some updated job_title", salary: 43}

      assert {:ok, %Employee{} = employee} = Employees.update_employee(employee, update_attrs)
      assert employee.full_name == "some updated full_name"
      assert employee.job_title == "some updated job_title"
      assert employee.salary == 43
    end

    test "update_employee/2 with invalid data returns error changeset" do
      employee = employee_fixture()
      assert {:error, %Ecto.Changeset{}} = Employees.update_employee(employee, @invalid_attrs)
      assert employee == Employees.get_employee!(employee.id)
    end

    test "delete_employee/1 deletes the employee" do
      employee = employee_fixture()
      assert {:ok, %Employee{}} = Employees.delete_employee(employee)
      assert_raise Ecto.NoResultsError, fn -> Employees.get_employee!(employee.id) end
    end

    test "change_employee/1 returns a employee changeset" do
      employee = employee_fixture()
      assert %Ecto.Changeset{} = Employees.change_employee(employee)
    end
  end

  defp employee_fixture(attrs \\ %{}) do
    {:ok, employee} =
      attrs
      |> Enum.into(%{
        full_name: "some full_name",
        job_title: "some job_title",
        salary: 42
      })
      |> Exercise.Employees.create_employee()

    employee
  end
end
