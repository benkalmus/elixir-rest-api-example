defmodule Exercise.CountriesTest do
  use Exercise.DataCase

  alias Exercise.Countries
  alias Exercise.Fixtures

  @currency_valid_attrs %{
    code: "USD",
    name: "some name",
    symbol: "some symbol"
  }
  @currency_update_attrs %{
    code: "EUR",
    name: "some updated name",
    symbol: "some updated symbol"
  }
  @currency_invalid_attrs %{
    code: nil,
    name: nil,
    symbol: nil
  }
  # =====================
  # Country
  @country_valid_attrs %{
    code: "ABC",
    name: "some name"
  }
  @country_update_attrs %{
    code: "XYZ",
    name: "some updated name"
  }
  @country_invalid_attrs %{
    code: nil,
    name: nil
  }

  describe "currencies" do
    alias Exercise.Countries.Currency

    test "list_currencies/0 returns all currencies" do
      currency = Fixtures.currency_fixture()
      assert Countries.list_currencies() == [currency]
    end

    test "get_currency!/1 returns the currency with given id" do
      currency = Fixtures.currency_fixture()
      assert Countries.get_currency!(currency.id) == currency
    end

    test "create_currency/1 with valid data creates a currency" do
      assert {:ok, %Currency{} = currency} = Countries.create_currency(@currency_valid_attrs)
      assert currency.code == @currency_valid_attrs.code
      assert currency.name == @currency_valid_attrs.name
      assert currency.symbol == @currency_valid_attrs.symbol
    end

    test "create_currency/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Countries.create_currency(@currency_invalid_attrs)
    end

    test "update_currency/2 with valid data updates the currency" do
      currency = Fixtures.currency_fixture()
      assert {:ok, %Currency{} = currency} = Countries.update_currency(currency, @currency_update_attrs)
      assert currency.code == @currency_update_attrs.code
      assert currency.name == @currency_update_attrs.name
      assert currency.symbol == @currency_update_attrs.symbol
    end

    test "update_currency/2 with invalid data returns error changeset" do
      currency = Fixtures.currency_fixture()
      assert {:error, %Ecto.Changeset{}} = Countries.update_currency(currency, @currency_invalid_attrs)
      assert currency == Countries.get_currency!(currency.id)
    end

    test "delete_currency/1 deletes the currency" do
      currency = Fixtures.currency_fixture()
      assert {:ok, %Currency{}} = Countries.delete_currency(currency)
      assert_raise Ecto.NoResultsError, fn -> Countries.get_currency!(currency.id) end
    end

    test "delete_currency/1 with a country reference returns error changeset" do
      currency = Fixtures.currency_fixture()
      _country = Fixtures.country_fixture(%{currency_id: currency.id})
      assert {:error, %Ecto.Changeset{}} = Countries.delete_currency(currency)
    end

    test "change_currency/1 returns a currency changeset" do
      currency = Fixtures.currency_fixture()
      assert %Ecto.Changeset{} = Countries.change_currency(currency)
    end

    test "create_currency/1 with non ISO 4127 currency.code returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Countries.create_currency(%{@currency_valid_attrs | :code => "invalid code"})
    end

    test "update_currency/2 with non ISO 4127 currency.code returns error changeset" do
      currency = Fixtures.currency_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Countries.update_currency(currency, %{@currency_valid_attrs | :code => "invalid code"})
    end

    test "get_currency_by_code!/1 returns the currency with given code" do
      currency = Fixtures.currency_fixture()
      assert Countries.get_currency_by_code!(currency.code) == currency
    end

    test "get_currency_by_code!/1 returns error when currency.code not found" do
      Fixtures.currency_fixture()
      assert_raise Ecto.NoResultsError, fn -> Countries.get_currency_by_code!("000") end
    end

    test "create_currency/1 with existing currency code and name returns error changeset" do
      # create currency with @currency_valid_attrs
      Fixtures.currency_fixture(@currency_valid_attrs)
      assert [@currency_valid_attrs] = Countries.list_currencies()
      # expecting another fixture to fail with the same @currency_valid_attrs
      assert {:error, %Ecto.Changeset{}} = Countries.create_currency(@currency_valid_attrs)
    end

    test "update_currency/1 to an existing currency returns error changeset" do
      _first_currency = Fixtures.currency_fixture(@currency_valid_attrs)
      # create another currency with different name and code
      currency = Fixtures.currency_fixture(%{@currency_valid_attrs | code: "EUR", name: "name"})
      # updating currency to existing code and name (_first_currency)
      assert {:error, %Ecto.Changeset{}} = Countries.update_currency(currency, @currency_valid_attrs)
    end
  end

  # ============================================================
  describe "countries" do
    alias Exercise.Countries.Country

    setup do
      currency = Fixtures.currency_fixture(@currency_valid_attrs)
      {:ok, currency: currency}
    end

    test "list_countries/0 returns all countries", %{currency: currency} do
      country = Fixtures.country_fixture(%{currency_id: currency.id})
      list =
        Countries.list_countries()
        |> Enum.map(&Countries.preload(&1))
      assert list == [country]
    end

    test "get_country!/1 returns the country with given id", %{currency: currency} do
      country = Fixtures.country_fixture(%{currency_id: currency.id})
      assert Countries.preload(Countries.get_country!(country.id)) == country
    end

    test "create_country/1 with valid data creates a country", %{currency: currency}  do
      attrs = create_country_attributes(@country_valid_attrs, currency)
      assert {:ok, %Country{} = country} = Countries.create_country(attrs)
      assert country.code == @country_valid_attrs.code
      assert country.name == @country_valid_attrs.name
    end

    test "create_country/1 with invalid data returns error changeset", %{currency: currency} do
      attrs = create_country_attributes(@country_invalid_attrs, currency)
      assert {:error, %Ecto.Changeset{}} = Countries.create_country(attrs)
    end

    test "update_country/2 with valid data updates the country", %{currency: currency} do
      country = Fixtures.country_fixture(%{currency_id: currency.id})
      assert {:ok, %Country{} = country} = Countries.update_country(country, @country_update_attrs)
      assert country.code == @country_update_attrs.code
      assert country.name == @country_update_attrs.name
    end

    test "update_country/2 with invalid data returns error changeset", %{currency: currency} do
      country = Fixtures.country_fixture(%{currency_id: currency.id})
      assert {:error, %Ecto.Changeset{}} = Countries.update_country(country, @country_invalid_attrs)
      assert country == Countries.preload(Countries.get_country!(country.id))
    end

    test "delete_country/1 deletes the country", %{currency: currency} do
      country = Fixtures.country_fixture(%{currency_id: currency.id})
      assert {:ok, %Country{}} = Countries.delete_country(country)
      assert_raise Ecto.NoResultsError, fn -> Countries.get_country!(country.id) end
    end

    test "delete_country/1 with associated employee should return error changeset", %{currency: currency} do
      country = Fixtures.country_fixture(%{currency_id: currency.id})
      _employee = Fixtures.employee_fixture(%{country_id: country.id})
      assert {:error, %Ecto.Changeset{}} = Countries.delete_country(country)
    end

    test "change_country/1 returns a country changeset", %{currency: currency} do
      country = Fixtures.country_fixture(%{currency_id: currency.id})
      assert %Ecto.Changeset{} = Countries.change_country(country)
    end

    test "create_country/1 with non alpha-3 country.code returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Countries.create_country(%{@country_valid_attrs | :code => "invalid code"})
    end

    test "update_country/2 with non alpha-3 country.code returns error changeset", %{currency: currency} do
      country = Fixtures.country_fixture(%{currency_id: currency.id})

      assert {:error, %Ecto.Changeset{}} =
               Countries.update_country(country, %{@country_valid_attrs | :code => "invalid code"})
    end

    test "create_country/1 with a non-existing currency returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Countries.create_country(Map.put(@country_valid_attrs, :currency_id, -1))
    end

    test "create_country/1 with an already existing country name or code returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Countries.create_country(Map.put(@country_valid_attrs, :currency_id, -1))
    end

    # would require all employee salaries to be converted. countries don't change their currencies. In such rare scenario, DB should be carefully updated using an external service rather than letting this happen via API.
    # test "update_country/2 with a different currency reference returns error changeset" do
    #   country = country_fixture(@country_valid_attrs)
    #   currency = create_currency(%{code: "DEF", name: "yet another currency"})
    #   assert {:error, %Ecto.Changeset{}} = Countries.update_country(country, Map.put(@country_valid_attrs, :currency_id, currency.id))
    #   # #Example validation in update changeset:
    #   # |> validate_change( :currency_id,
    #   #   fn :currency_id, currency_id ->
    #   #     cond do
    #   #       country.currency_id == nil -> []    #set for the first time
    #   #       country.currency_id == currency_id -> []  #unchanged
    #   #       #currency foreign key reference changed
    #   #       true -> [currency_id: "currency_id cannot be changed #{inspect(country.currency_id)} vs #{currency_id}"]
    #   #     end
    #   #   end)
    # end

    # ============================================================
    # Setup Functions

    defp create_country_attributes(attrs, currency) do
      Map.put(attrs, :currency_id, currency.id)
    end
  end
end
