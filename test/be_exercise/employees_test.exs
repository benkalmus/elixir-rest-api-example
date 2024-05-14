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
      salary: 42,
      country_id: :todo
    }

    test "list_employees/0 returns all employees", %{country: country} do
      employee = Fixtures.employee_fixture(%{country_id: country.id})
      assert Employees.list_employees() == [employee]
    end

    test "get_employee!/1 returns the employee with given id", %{country: country} do
      employee = Fixtures.employee_fixture(%{country_id: country.id})
      assert Employees.get_employee!(employee.id) == employee
    end

    test "create_employee/1 with valid data creates a employee", %{country:  country} do
      assert {:ok, %Employee{} = employee} = Employees.create_employee(Map.put(@valid_attrs, :country_id, country.id))
      assert employee.full_name == "some full_name"
      assert employee.job_title == "some job_title"
      assert employee.salary == 42
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
      assert employee.salary == 43
    end

    test "update_employee/2 with invalid data returns error changeset", %{country: country} do
      employee = Fixtures.employee_fixture(%{country_id: country.id})
      assert {:error, %Ecto.Changeset{}} = Employees.update_employee(employee, @invalid_attrs)
      assert employee == Employees.get_employee!(employee.id)
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

    # todo does this belong in countries test?
    test "remove country with associated employee should return error changeset", %{country: country} do
      _employee = Fixtures.employee_fixture(%{country_id: country.id})
      assert {:error, %Ecto.Changeset{}} = Exercise.Countries.delete_country(country)
    end

    test "create_employee/1 with a non-existing country returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Employees.create_employee(Map.put(@valid_attrs, :country_id, -1))
    end

    #invalid salary insert, -10_000
    #updating employee's country, should convert salary

    test "batch_write/1 with a valid list of employees creates them", %{country: country} do
      employee_batches =  [
        %{full_name: "John Smith", job_title: "Developer", country_id: country.id, salary: 50_000},
        %{full_name: "Jack Johnson", job_title: "Manager", country_id: country.id, salary: 60_000}
      ]
      assert {:ok, successful, []} = Employees.batch_write(employee_batches)

      assert length(successful) == length(employee_batches)
      # ensure employees were written to DB, retrieve and compare them
      all = Employees.list_employees()
      #TODO improve this comparison, on error we can't see which element failed
      assert true = Enum.all?(successful, fn employee ->
        Enum.any?(all, fn e ->
          e == employee |> Exercise.Repo.preload(:country)
        end)
      end)
    end

    #todo
      # valid and invalid lists
    #

  end
end
