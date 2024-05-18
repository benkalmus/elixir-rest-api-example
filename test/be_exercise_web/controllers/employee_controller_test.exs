defmodule ExerciseWeb.EmployeeControllerTest do
  use ExerciseWeb.ConnCase
  alias Exercise.Employees.Employee
  alias Exercise.Employees
  alias Exercise.Fixtures

  @create_attrs %{
    full_name: "some full_name",
    job_title: "some job_title",
    salary: 42
  }
  @update_attrs %{
    full_name: "some updated full_name",
    job_title: "some updated job_title",
    salary: 43
  }
  @invalid_attrs %{full_name: nil, job_title: nil, salary: nil}

  setup %{conn: conn} do
    currency = Fixtures.currency_fixture()
    country = Fixtures.country_fixture(%{currency_id: currency.id})
    {:ok,
      conn: put_req_header(conn, "accept", "application/json"),
      country: country,
      currency: currency
    }
  end

  describe "index" do
    test "lists zero employees", %{conn: conn} do
      conn = get(conn, ~p"/api/employees")
      assert json_response(conn, 200)["data"] == []
    end

    test "lists all employees", %{conn: conn, country: country = %{id: country_id}} do
      %Employee{id: id} = Fixtures.employee_fixture(employee_attr(@create_attrs, country))
      conn = get(conn, ~p"/api/employees")
      country = Exercise.Repo.preload(country, :currency)
      currency_code = country.currency.code
      assert [%{
        "id" => ^id,
        "full_name" => "some full_name",
        "job_title" => "some job_title",
        "salary" => 42,
        "country_id" => ^country_id,
        "currency_code" => ^currency_code
      }] = json_response(conn, 200)["data"]
    end
  end

  describe "create employee" do
    test "renders employee when data is valid", %{conn: conn, country: country} do
      conn = post(conn, ~p"/api/employees", employee: employee_attr(@create_attrs, country))
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/employees/#{id}")

      assert %{
               "id" => ^id,
               "full_name" => "some full_name",
               "job_title" => "some job_title",
               "salary" => 42
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, country: country} do
      conn = post(conn, ~p"/api/employees", employee:  employee_attr(@invalid_attrs, country))
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "batch_write returns lists of successes and failures", %{conn: conn, country: country} do
      country_id = country.id
      employee_batches =  [
        ## valid
        %{full_name: "John Smith", job_title: "Developer", country_id: country_id, salary: 50000},
        ## invalid
        %{full_name: "Jack Johnson", job_title: "Manager", country_id: -1, salary: 60000}
      ]
      conn = post(conn, Routes.employee_path(conn, :batch_write), employees: employee_batches)
      response = json_response(conn, 200)
      assert [%{
        "full_name" => "John Smith",
        "job_title" => "Developer",
        "salary" => 50000,
        "country_id" => ^country_id
      }] = response["successful"]

      # failures should be descriptive:
      assert [%{
        "error" => %{"country_id" => ["does not exist"]},
        "params" => %{
          "full_name" => "Jack Johnson",
          "job_title" => "Manager",
          "salary" => 60000,
          "country_id" => -1
        }
      }] = response["failed"]

    end
  end

  describe "show employee" do
    setup [:create_employee]

    test "renders employee when id is valid", %{conn: conn, employee: employee} do
      conn = get(conn, Routes.employee_path(conn, :show, employee.id))
      assert %{
               "id" => employee.id,
               "full_name" => employee.full_name,
               "salary" => employee.salary,
               "job_title" => employee.job_title,
               "country_id" => employee.country.id,
               "currency_code" => employee.country.currency.code
             } == json_response(conn, 200)["data"]
    end

    test "renders errors when id do not exist", %{conn: conn} do
      assert_error_sent 404, fn ->
        get(conn, Routes.employee_path(conn, :show, -1))
      end
    end
  end

  describe "update employee" do
    setup [:create_employee]

    test "renders employee when data is valid", %{conn: conn, employee: %Employee{id: id} = employee, country: country} do
      conn = put(conn, ~p"/api/employees/#{employee}", employee: employee_attr(@update_attrs, country))
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/employees/#{id}")

      assert %{
               "id" => id,
               "full_name" => "some updated full_name",
               "job_title" => "some updated job_title",
               "salary" => 43,
               "country_id" => employee.country.id,
               "currency_code" => employee.country.currency.code
             } == json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, employee: employee, country: country} do
      conn = put(conn, ~p"/api/employees/#{employee}", employee: employee_attr(@invalid_attrs, country))
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete employee" do
    setup [:create_employee]

    test "deletes chosen employee", %{conn: conn, employee: employee} do
      conn = delete(conn, ~p"/api/employees/#{employee}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/employees/#{employee}")
      end
    end
  end
require Logger
  describe "employee_metrics" do
    setup [:create_employees_for_metrics]

    test "employee metrics by country id returns a json response containing valid metrics", %{conn: conn, country: country} do
      min = 50000
      max = 100000
      mean = 70000
      code = country.currency.code

      conn = get(conn, Routes.employee_path(conn, :metrics_by_country, country_id: country.id))
      assert %{
        "min" => ^min,
        "max" => ^max,
        "mean" => ^mean,
        "currency_code" => ^code
             } = json_response(conn, 200)
    end

    test "employee metrics by invalid country id returns an error", %{conn: conn} do
      conn = get(conn, Routes.employee_path(conn, :metrics_by_country, country_id: -1))

      assert %{
        "errors" => %{
          "detail" => "Not Found"
        }
      } = json_response(conn, 404)
    end

    test "employee metrics by job_title returns a json response containing valid metrics", %{conn: conn} do
      target_currency = "USD"
      employee_max = 100000   # employee with highest salary in GBP
      job_title = "Manager"
      # convert one of the other employees salary to target_currency
      {:ok, max_in_usd} = Exercise.Services.CurrencyConverter.convert("GBP", target_currency, employee_max)
      max = round(max_in_usd)
      # calculate mean
      mean = round((60000 + 100000 + max) / 3)

      conn = get(conn, Routes.employee_path(conn, :metrics_by_job_title, job_title: job_title, target_currency: target_currency))
      assert %{
        "min" => 60000,
        "max" => ^max,
        "mean" => ^mean,
        "currency_code" => ^target_currency
             } = json_response(conn, 200)
    end

    test "employee metrics by invalid job_title returns an error", %{conn: conn} do
      conn = get(conn, Routes.employee_path(conn, :metrics_by_job_title, job_title: "job_title", target_currency: "target_currency"))

      assert %{
        "errors" => %{
          "detail" => "Not Found"
        }
      } = json_response(conn, 404)
    end

  end

  defp create_employee(%{country: country}) do
    employee = Fixtures.employee_fixture(%{country_id: country.id})
    %{employee: employee}
  end

  defp employee_attr(attrs, %{id: id} = _country) do
    Map.put(attrs, :country_id, id)
  end

  defp create_employees_for_metrics(%{country: country}) do
    another_currency = Fixtures.currency_fixture(%{code: "GBP", name: "British Pound Sterling"})
    another_country = Fixtures.country_fixture(%{currency_id: another_currency.id, code: "GBP", name: "United Kingdom"})

    # a mixture of employees with different countries and job titles
    employee_batches =  [
      %{full_name: "John Smith", job_title: "Developer", country_id: country.id, salary: 50000},
      %{full_name: "Jack Johnson", job_title: "Manager", country_id: country.id, salary: 60000},
      %{full_name: "John Jackson", job_title: "Manager", country_id: country.id, salary: 100000},
      %{full_name: "Billy Jones", job_title: "Developer", country_id: another_country.id, salary: 100000},
      %{full_name: "Adam McCoy", job_title: "Manager", country_id: another_country.id, salary: 100000}
    ]

    Employees.batch_write(employee_batches)

    %{
      another_currency: another_currency,
      another_country: another_country,
      employees: employee_batches
    }
  end

end
