defmodule ExerciseWeb.CountryControllerTest do
  use ExerciseWeb.ConnCase

  alias Exercise.Countries
  alias Exercise.Countries.Country
  alias Exercise.Fixtures

  @create_attrs %{
    code: "ABC",
    name: "some name"
  }
  @update_attrs %{
    code: "XYZ",
    name: "some updated name"
  }
  @invalid_attrs %{code: nil, name: nil}
  @valid_currency_attrs %{
    code: "ABC",
    name: "some name",
    symbol: "some symbol"
  }

  setup %{conn: conn} do
    currency = Fixtures.currency_fixture(@valid_currency_attrs)
    {:ok, conn: put_req_header(conn, "accept", "application/json"), currency: currency}
  end

  describe "index" do
    test "lists empty countries", %{conn: conn} do
      conn = get(conn, Routes.country_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end

    test "lists all countries", %{conn: conn} = ctx do
      %{:country => country} = create_country(ctx)
      conn = get(conn, Routes.country_path(conn, :index))

      assert [
               %{
                 "id" => country.id,
                 "code" => country.code,
                 "name" => country.name
               }
             ] == json_response(conn, 200)["data"]
    end
  end

  describe "create country" do
    test "renders country when data is valid", %{conn: conn, currency: currency} do
      attrs = @create_attrs |> Map.put(:currency_id, currency.id)
      conn = post(conn, Routes.country_path(conn, :create), country: attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.country_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "code" => "ABC",
               "name" => "some name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.country_path(conn, :create), country: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "show country" do
    setup [:create_country]

    test "renders country when id is valid", %{conn: conn, country: country} do
      conn = get(conn, Routes.country_path(conn, :show, country.id))

      assert %{
               "id" => country.id,
               "code" => country.code,
               "name" => country.name
             } == json_response(conn, 200)["data"]
    end

    test "renders errors when id or code do not exist", %{conn: conn} do
      assert_error_sent 404, fn ->
        get(conn, Routes.country_path(conn, :show, -1))
      end
    end
  end

  describe "update country" do
    setup [:create_country]

    test "renders country when data is valid", %{conn: conn, country: %Country{id: id} = country} do
      conn = put(conn, Routes.country_path(conn, :update, country), country: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.country_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "code" => "XYZ",
               "name" => "some updated name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, country: country} do
      conn = put(conn, Routes.country_path(conn, :update, country), country: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete country" do
    setup [:create_country]

    test "deletes chosen country", %{conn: conn, country: country} do
      conn = delete(conn, Routes.country_path(conn, :delete, country))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.country_path(conn, :show, country))
      end
    end
  end

  defp create_country(ctx) do
    country = Fixtures.country_fixture(@create_attrs |> Map.put(:currency_id, ctx.currency.id))
    ctx
      |> Map.put(:country, country)
  end
end
