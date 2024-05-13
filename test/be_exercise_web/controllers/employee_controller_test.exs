defmodule ExerciseWeb.EmployeeControllerTest do
  use ExerciseWeb.ConnCase
  alias Exercise.Employees.Employee

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
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all employees", %{conn: conn} do
      conn = get(conn, ~p"/api/employees")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create employee" do
    test "renders employee when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/employees", employee: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/employees/#{id}")

      assert %{
               "id" => ^id,
               "full_name" => "some full_name",
               "job_title" => "some job_title",
               "salary" => 42
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/employees", employee: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update employee" do
    setup [:create_employee]

    test "renders employee when data is valid", %{conn: conn, employee: %Employee{id: id} = employee} do
      conn = put(conn, ~p"/api/employees/#{employee}", employee: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/employees/#{id}")

      assert %{
               "id" => ^id,
               "full_name" => "some updated full_name",
               "job_title" => "some updated job_title",
               "salary" => 43
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, employee: employee} do
      conn = put(conn, ~p"/api/employees/#{employee}", employee: @invalid_attrs)
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

  defp create_employee(_) do
    employee = employee_fixture()
    %{employee: employee}
  end
end
