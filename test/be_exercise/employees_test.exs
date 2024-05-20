defmodule Exercise.EmployeesTest do
  use Exercise.DataCase

  alias Exercise.Services.CurrencyConverter
  alias Exercise.Employees.Employee
  alias Exercise.Employees
  alias Exercise.Fixtures

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
    country_id: :placeholder
  }

  setup do
    currency = Fixtures.currency_fixture()
    country = Fixtures.country_fixture(%{currency_id: currency.id})
    {:ok, %{country: country}}
  end

  describe "employees CRUD tests" do
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

    test "create_employee/1 with valid data creates a employee", %{country: country} do
      assert {:ok, %Employee{} = employee} =
               Employees.create_employee(Map.put(@valid_attrs, :country_id, country.id))

      assert employee.full_name == "some full_name"
      assert employee.job_title == "some job_title"
      assert employee.salary == 42
      assert employee.country_id == country.id
    end

    test "create_employee/1 with invalid data returns error changeset", %{country: country} do
      assert {:error, %Ecto.Changeset{}} =
               Employees.create_employee(Map.put(@invalid_attrs, :country_id, country.id))
    end

    test "update_employee/2 with valid data updates the employee", %{country: country} do
      employee = Fixtures.employee_fixture(%{country_id: country.id})

      update_attrs = %{
        full_name: "some updated full_name",
        job_title: "some updated job_title",
        salary: 43
      }

      assert {:ok, %Employee{} = employee} = Employees.update_employee(employee, update_attrs)
      assert employee.full_name == "some updated full_name"
      assert employee.job_title == "some updated job_title"
      assert employee.salary == 43
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
      attr = %{@valid_attrs | country_id: country.id, salary: -100}
      assert {:error, %Ecto.Changeset{}} = Employees.create_employee(attr)
    end
  end

  describe "batch write tests" do
    setup [:employee_batches]

    test "batch_write/1 with a valid list of employees creates them", %{
      employees: employee_batches
    } do
      assert {:ok, successful, []} = Employees.batch_write(employee_batches)
      assert length(successful) == length(employee_batches)
      assert_employee_lists(Employees.list_employees(), successful)
    end

    test "batch_write/1 with invalid employees reports them", %{employees: employee_batches} do
      invalid_employee = %{
        full_name: "John Smith",
        job_title: "Developer",
        country_id: -1,
        salary: 50000
      }

      assert {:ok, _successful, invalid} =
               Employees.batch_write([invalid_employee | employee_batches])

      assert [{^invalid_employee, %Ecto.Changeset{} = changeset}] = invalid
      assert changeset.valid? == false
    end

    test "batch_write_unsafe/1 with a valid list of employees creates them", %{
      employees: employee_batches
    } do
      assert %{
               valid_attr: valid_attr,
               invalid_attr: [],
               insert_results: results
             } = Employees.batch_write_unsafe(employee_batches)

      assert length(valid_attr) == length(employee_batches)

      # sort by full name for the following comparison with employees stored in DB
      sorted_valid_attr = Enum.sort_by(valid_attr, fn e -> e.full_name end)

      # compare inserted employees to employees attributes we tried to insert
      Employees.list_employees()
      |> Enum.sort_by(fn e -> e.full_name end)
      # zip {actual written employee, attributes we tried to insert}
      |> Enum.zip(sorted_valid_attr)
      |> Enum.each(fn {db_employee, attr} ->
        assert db_employee.full_name == attr.full_name
        assert db_employee.job_title == attr.job_title
        assert db_employee.salary == attr.salary
        assert db_employee.country_id == attr.country_id
      end)

      # ensure transaction results were :ok
      Enum.each(results, fn r ->
        assert {:ok, _} = r
      end)
    end

    ## todo add invalid test for unsafe batch writes

    ## Setup
    defp employee_batches(%{country: country}) do
      employee_batches = [
        %{full_name: "John Smith", job_title: "Developer", country_id: country.id, salary: 50000},
        %{full_name: "Jack Johnson", job_title: "Manager", country_id: country.id, salary: 60000}
      ]

      %{employees: employee_batches}
    end
  end

  describe "employee queries tests" do
    setup [:valid_employee_batches]

    test "get_all_by_country_id/1 should return all employees given a valid country id", %{
      country: country,
      employees: employee_batches
    } do
      assert {:ok, successful, []} = Employees.batch_write(employee_batches)
      # filter out successfully inserted employees by country.id
      successful = Enum.filter(successful, fn e -> e.country_id == country.id end)
      # run query
      employees = Employees.get_all_by_country_id(country.id)
      # Assert employees were written to DB, retrieve with preload and compare them
      assert_employee_lists(employees, successful)
    end

    test "get_all_by_country_id/1 should return no employees given a country with no employees",
         %{employees: employee_batches} do
      assert {:ok, _successful, []} = Employees.batch_write(employee_batches)
      assert [] = Employees.get_all_by_country_id(-1)
    end

    test "get_all_by_job_title/1 should return all employees given a valid job title", %{
      employees: employee_batches
    } do
      job_title = "Manager"

      assert {:ok, successful, []} = Employees.batch_write(employee_batches)
      # filter out successfully inserted employees by job_title
      successful = Enum.filter(successful, fn e -> e.job_title == job_title end)
      # run query
      employees = Employees.get_all_by_job_title(job_title)
      assert_employee_lists(employees, successful)
    end

    test "get_all_by_job_title/1 should return no employees given a job_title with no employees",
         %{country: country} do
      Fixtures.employee_fixture(%{country_id: country.id})
      assert [] = Employees.get_all_by_job_title("This job title shouldn't exist")
    end
  end

  describe "salary metrics tests" do
    setup [:valid_employee_batches]

    test "salary_metrics_by_country/1 should return min, max, avg salary for all employees in a country",
         %{country: country, employees: employee_batches} do
      min = 50000
      max = 100_000
      mean = 70000
      code = country.currency.code

      Employees.batch_write(employee_batches)

      # run query
      assert {:ok, result} = Employees.salary_metrics_by_country(country.id)

      assert %{
               min: ^min,
               max: ^max,
               mean: ^mean,
               currency_code: ^code
             } = result
    end

    test "salary_metrics_by_country/1 should return error if country has no employees", %{
      employees: employee_batches
    } do
      Employees.batch_write(employee_batches)

      # run query
      assert {:error, :not_found} = Employees.salary_metrics_by_country(-1)
    end

    test "salary_metrics_by_jobtitle/1 should return salary metrics for employees with given jobtitle",
         %{employees: employee_batches} do
      target_currency = "USD"
      # employee with highest salary in GBP
      employee_max = 100_000
      job_title = "Manager"

      Employees.batch_write(employee_batches)
      # run query
      assert {:ok, result} = Employees.salary_metrics_by_job_title(job_title, target_currency)

      # convert one of the other employees salary to target_currency
      {:ok, max_in_usd} = CurrencyConverter.convert("GBP", target_currency, employee_max)
      max = round(max_in_usd)
      # calculate mean
      mean = round((60000 + 100_000 + max) / 3)

      assert %{
               # precalculated values:
               min: 60000,
               max: ^max,
               mean: ^mean,
               currency_code: ^target_currency
             } = result
    end

    test "salary_metrics_by_jobtitle/1 should return error if job_title has no employee", %{
      employees: employee_batches
    } do
      Employees.batch_write(employee_batches)

      # run query
      assert {:error, :not_found} =
               Employees.salary_metrics_by_job_title("This job title shouldn't exist", "USD")
    end
  end

  # ================================================
  ## Test Helper functions

  # asserts two %Employee{} lists are identical. Preloads each employee
  defp assert_employee_lists(expected, actual) do
    expected =
      expected
      |> Enum.map(&Employees.preload(&1))
      |> Enum.sort()

    actual =
      actual
      |> Enum.map(&Employees.preload(&1))
      |> Enum.sort()

    assert expected == actual
  end

  defp valid_employee_batches(%{country: country}) do
    another_currency = Fixtures.currency_fixture(%{code: "GBP", name: "British Pound Sterling"})

    another_country =
      Fixtures.country_fixture(%{
        currency_id: another_currency.id,
        code: "GBP",
        name: "United Kingdom"
      })

    # a mixture of employees with different countries and job titles
    employee_batches = [
      %{full_name: "John Smith", job_title: "Developer", country_id: country.id, salary: 50000},
      %{full_name: "Jack Johnson", job_title: "Manager", country_id: country.id, salary: 60000},
      %{full_name: "John Jackson", job_title: "Manager", country_id: country.id, salary: 100_000},
      %{
        full_name: "Billy Jones",
        job_title: "Developer",
        country_id: another_country.id,
        salary: 100_000
      },
      %{
        full_name: "Adam McCoy",
        job_title: "Manager",
        country_id: another_country.id,
        salary: 100_000
      }
    ]

    %{
      another_currency: another_currency,
      another_country: another_country,
      employees: employee_batches
    }
  end
end
