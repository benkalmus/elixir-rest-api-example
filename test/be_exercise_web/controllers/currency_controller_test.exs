defmodule ExerciseWeb.CurrencyControllerTest do
  use ExerciseWeb.ConnCase

  alias Exercise.Countries.Currency
  alias Exercise.Fixtures

  @create_attrs %{
    code: "USD",
    name: "some name",
    symbol: "some symbol"
  }
  @update_attrs %{
    code: "EUR",
    name: "some updated name",
    symbol: "some updated symbol"
  }
  @invalid_attrs %{code: nil, name: nil, symbol: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists empty currencies", %{conn: conn} do
      conn = get(conn, Routes.currency_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end

    test "lists all currencies", %{conn: conn} do
      %{currency: currency} = create_currency([])
      conn = get(conn, Routes.currency_path(conn, :index))

      assert [
               %{
                 "id" => currency.id,
                 "code" => currency.code,
                 "name" => currency.name,
                 "symbol" => currency.symbol
               }
             ] == json_response(conn, 200)["data"]
    end
  end

  describe "create currency" do
    test "renders currency when data is valid", %{conn: conn} do
      conn = post(conn, Routes.currency_path(conn, :create), currency: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.currency_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "code" => "USD",
               "name" => "some name",
               "symbol" => "some symbol"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.currency_path(conn, :create), currency: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "show currency" do
    setup [:create_currency]

    test "renders currency when id is valid", %{conn: conn, currency: %Currency{} = currency} do
      conn = get(conn, Routes.currency_path(conn, :show, currency.id))

      assert %{
               "id" => currency.id,
               "code" => currency.code,
               "name" => currency.name,
               "symbol" => currency.symbol
             } == json_response(conn, 200)["data"]
    end

    test "renders currency when code is valid", %{conn: conn, currency: %Currency{} = currency} do
      conn = get(conn, Routes.currency_path(conn, :get_by_code, currency.code))

      assert %{
               "id" => currency.id,
               "code" => currency.code,
               "name" => currency.name,
               "symbol" => currency.symbol
             } == json_response(conn, 200)["data"]
    end

    test "renders errors when id or code do not exist", %{conn: conn} do
      assert_error_sent 404, fn ->
        get(conn, Routes.currency_path(conn, :show, -1))
      end

      assert_error_sent 404, fn ->
        get(conn, Routes.currency_path(conn, :get_by_code, "test"))
      end
    end
  end

  describe "update currency" do
    setup [:create_currency]

    test "renders currency when data is valid", %{
      conn: conn,
      currency: %Currency{id: id} = currency
    } do
      conn = put(conn, Routes.currency_path(conn, :update, currency), currency: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.currency_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "code" => "EUR",
               "name" => "some updated name",
               "symbol" => "some updated symbol"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, currency: currency} do
      conn = put(conn, Routes.currency_path(conn, :update, currency), currency: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete currency" do
    setup [:create_currency]

    test "deletes chosen currency", %{conn: conn, currency: currency} do
      conn = delete(conn, Routes.currency_path(conn, :delete, currency))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.currency_path(conn, :show, currency))
      end
    end
  end

  defp create_currency(_) do
    currency = Fixtures.currency_fixture()
    %{currency: currency}
  end
end
