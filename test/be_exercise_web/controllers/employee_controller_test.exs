defmodule ExerciseWeb.EmployeeControllerTest do
  use ExerciseWeb.ConnCase
  alias Exercise.Employees.Employee
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
    test "lists all employees", %{conn: conn} do
      conn = get(conn, ~p"/api/employees")
      assert json_response(conn, 200)["data"] == []
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
  end

  describe "update employee" do
    setup [:create_employee]

    test "renders employee when data is valid", %{conn: conn, employee: %Employee{id: id} = employee, country: country} do
      conn = put(conn, ~p"/api/employees/#{employee}", employee: employee_attr(@update_attrs, country))
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/employees/#{id}")

      assert %{
               "id" => ^id,
               "full_name" => "some updated full_name",
               "job_title" => "some updated job_title",
               "salary" => 43
             } = json_response(conn, 200)["data"]
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


  defp create_employee(%{country: country}) do
    employee = Fixtures.employee_fixture(%{country_id: country.id})
    %{employee: employee}
  end

  defp employee_attr(attrs, %{id: id} = _country) do
    Map.put(attrs, :country_id, id)
  end
end
