defmodule Exercise.EmployeesTest do
  use Exercise.DataCase
  alias Exercise.Employees
  alias Exercise.Fixtures

  setup do
    currency = Fixtures.currency_fixture()
    country = Fixtures.country_fixture(%{currency_id: currency.id})
    {:ok, %{country: country}}
  end

  describe "employees" do
    alias Exercise.Employees.Employee

    @invalid_attrs %{
      full_name: nil,
      job_title: nil,
      salary: nil,
      country_id: nil
    }
    @valid_attrs %{
      full_name: "some full_name",
      job_title: "some job_title",
      salary: Decimal.new(42),
      country_id: :todo
    }

    test "list_employees/0 returns all employees", %{country: country} do
      employee = Fixtures.employee_fixture(%{country_id: country.id})
      list =
        Employees.list_employees()
        |> Enum.map(&Employees.preload(&1))
      assert list == [employee]
    end

    test "get_employee!/1 returns the employee with given id", %{country: country} do
      employee = Fixtures.employee_fixture(%{country_id: country.id})
      get =
        Employees.get_employee!(employee.id)
        |> Employees.preload()
      assert get == employee
    end

    test "create_employee/1 with valid data creates a employee", %{country:  country} do
      assert {:ok, %Employee{} = employee} = Employees.create_employee(Map.put(@valid_attrs, :country_id, country.id))
      assert employee.full_name == "some full_name"
      assert employee.job_title == "some job_title"
      assert employee.salary == Decimal.new(42)
      assert employee.country_id == country.id
    end

    test "create_employee/1 with invalid data returns error changeset", %{country:  country} do
      assert {:error, %Ecto.Changeset{}} = Employees.create_employee(Map.put(@invalid_attrs, :country_id, country.id))
    end

    test "update_employee/2 with valid data updates the employee", %{country: country} do
      employee = Fixtures.employee_fixture(%{country_id: country.id})
      update_attrs = %{full_name: "some updated full_name", job_title: "some updated job_title", salary: 43}

      assert {:ok, %Employee{} = employee} = Employees.update_employee(employee, update_attrs)
      assert employee.full_name == "some updated full_name"
      assert employee.job_title == "some updated job_title"
      assert employee.salary == Decimal.new(43)
      assert employee.country_id == country.id
    end

    test "update_employee/2 with invalid data returns error changeset", %{country: country} do
      employee = Fixtures.employee_fixture(%{country_id: country.id})
      assert {:error, %Ecto.Changeset{}} = Employees.update_employee(employee, @invalid_attrs)
      assert employee == Employees.preload(Employees.get_employee!(employee.id))
    end

    test "delete_employee/1 deletes the employee", %{country: country} do
      employee = Fixtures.employee_fixture(%{country_id: country.id})
      assert {:ok, %Employee{}} = Employees.delete_employee(employee)
      assert_raise Ecto.NoResultsError, fn -> Employees.get_employee!(employee.id) end
    end

    test "change_employee/1 returns a employee changeset", %{country: country} do
      employee = Fixtures.employee_fixture(%{country_id: country.id})
      assert %Ecto.Changeset{} = Employees.change_employee(employee)
    end

    test "create_employee/1 with a non-existing country returns error changeset" do
      attr = %{@valid_attrs | country_id: -1}
      assert {:error, %Ecto.Changeset{}} = Employees.create_employee(attr)
    end

    test "create_employee/1 with an invalid salary returns error changeset", %{country: country} do
      attr = %{@valid_attrs | country_id: country.id, salary: Decimal.new(-100)}
      assert {:error, %Ecto.Changeset{}} = Employees.create_employee(attr)
    end

    #updating employee's country, should require updated salary field

    test "batch_write/1 with a valid list of employees creates them", %{country: country} do
      employee_batches =  [
        %{full_name: "John Smith", job_title: "Developer", country_id: country.id, salary: Decimal.new("50000.00")},
        %{full_name: "Jack Johnson", job_title: "Manager", country_id: country.id, salary: Decimal.new("60000.00")}
      ]
      assert {:ok, successful, []} = Employees.batch_write(employee_batches)

      assert length(successful) == length(employee_batches)
      # ensure employees were written to DB, retrieve and compare them
      db_employees =
        Employees.list_employees()
        |> Enum.map(&Employees.preload(&1))
        |> Enum.sort()

      successful =
        successful
        |> Enum.map(&Employees.preload(&1))
        |> Enum.sort()

      assert db_employees == successful
    end

    #todo
      # valid and invalid lists
    #

  end
end
