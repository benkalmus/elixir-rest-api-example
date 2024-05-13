defmodule ExerciseWeb.CountryControllerTest do
  use ExerciseWeb.ConnCase

  alias Exercise.Countries
  alias Exercise.Countries.Country

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
    {:ok, currency} = Countries.create_currency(@valid_currency_attrs)
    {:ok, conn: put_req_header(conn, "accept", "application/json"), currency: currency}
  end

  describe "index" do
    test "lists all countries", %{conn: conn} do
      conn = get(conn, Routes.country_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
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
    {:ok, country} = Countries.create_country(@create_attrs |> Map.put(:currency_id, ctx.currency.id))
    # country = fixture(:country)
    ctx |> Map.put(:country, country)
  end
end
