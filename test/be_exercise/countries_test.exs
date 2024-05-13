defmodule Exercise.CountriesTest do
  use Exercise.DataCase

  alias Exercise.Countries

  describe "currencies" do
    alias Exercise.Countries.Currency

    @valid_attrs %{
      code: "ABC",
      name: "some name",
      symbol: "some symbol"
    }
    @update_attrs %{
      code: "XYZ",
      name: "some updated name",
      symbol: "some updated symbol"
    }
    @invalid_attrs %{
      code: nil,
      name: nil,
      symbol: nil
    }

    def currency_fixture(attrs \\ %{}) do
      {:ok, currency} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Countries.create_currency()

      currency
    end

    test "list_currencies/0 returns all currencies" do
      currency = currency_fixture()
      assert Countries.list_currencies() == [currency]
    end

    test "get_currency!/1 returns the currency with given id" do
      currency = currency_fixture()
      assert Countries.get_currency!(currency.id) == currency
    end

    test "create_currency/1 with valid data creates a currency" do
      assert {:ok, %Currency{} = currency} = Countries.create_currency(@valid_attrs)
      assert currency.code == @valid_attrs.code
      assert currency.name == @valid_attrs.name
      assert currency.symbol == @valid_attrs.symbol
    end

    test "create_currency/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Countries.create_currency(@invalid_attrs)
    end

    test "update_currency/2 with valid data updates the currency" do
      currency = currency_fixture()
      assert {:ok, %Currency{} = currency} = Countries.update_currency(currency, @update_attrs)
      assert currency.code == @update_attrs.code
      assert currency.name == @update_attrs.name
      assert currency.symbol == @update_attrs.symbol
    end

    test "update_currency/2 with invalid data returns error changeset" do
      currency = currency_fixture()
      assert {:error, %Ecto.Changeset{}} = Countries.update_currency(currency, @invalid_attrs)
      assert currency == Countries.get_currency!(currency.id)
    end

    test "delete_currency/1 deletes the currency" do
      currency = currency_fixture()
      assert {:ok, %Currency{}} = Countries.delete_currency(currency)
      assert_raise Ecto.NoResultsError, fn -> Countries.get_currency!(currency.id) end
    end

    test "change_currency/1 returns a currency changeset" do
      currency = currency_fixture()
      assert %Ecto.Changeset{} = Countries.change_currency(currency)
    end

    test "create_currency/1 with non ISO 4127 currency.code returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Countries.create_currency(%{@valid_attrs | :code => "invalid code"})
    end

    test "update_currency/2 with non ISO 4127 currency.code returns error changeset" do
      currency = currency_fixture()
      assert {:error, %Ecto.Changeset{}}  = Countries.update_currency(currency, %{@valid_attrs | :code => "invalid code"})
    end

    test "get_currency_by_code!/1 returns the currency with given code" do
      currency = currency_fixture()
      assert Countries.get_currency_by_code!(currency.code) == currency
    end

    test "get_currency_by_code!/1 returns error when currency.code not found" do
      currency_fixture()
      assert_raise Ecto.NoResultsError, fn ->  Countries.get_currency_by_code!("000") end
    end

  end

  # ============================================================
  describe "countries" do
    alias Exercise.Countries.Country

    @valid_attrs %{code: "ABC", name: "some name"}
    @update_attrs %{code: "XYZ", name: "some updated name"}
    @invalid_attrs %{code: nil, name: nil}

    def country_fixture(attrs \\ %{}) do
      {:ok, country} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Countries.create_country()

      country
    end

    test "list_countries/0 returns all countries" do
      country = country_fixture()
      assert Countries.list_countries() == [country]
    end

    test "get_country!/1 returns the country with given id" do
      country = country_fixture()
      assert Countries.get_country!(country.id) == country
    end

    test "create_country/1 with valid data creates a country" do
      assert {:ok, %Country{} = country} = Countries.create_country(@valid_attrs)
      assert country.code == @valid_attrs.code
      assert country.name == @valid_attrs.name
    end

    test "create_country/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Countries.create_country(@invalid_attrs)
    end

    test "update_country/2 with valid data updates the country" do
      country = country_fixture()
      assert {:ok, %Country{} = country} = Countries.update_country(country, @update_attrs)
      assert country.code == @update_attrs.code
      assert country.name == @update_attrs.name
    end

    test "update_country/2 with invalid data returns error changeset" do
      country = country_fixture()
      assert {:error, %Ecto.Changeset{}} = Countries.update_country(country, @invalid_attrs)
      assert country == Countries.get_country!(country.id)
    end

    test "delete_country/1 deletes the country" do
      country = country_fixture()
      assert {:ok, %Country{}} = Countries.delete_country(country)
      assert_raise Ecto.NoResultsError, fn -> Countries.get_country!(country.id) end
    end

    test "change_country/1 returns a country changeset" do
      country = country_fixture()
      assert %Ecto.Changeset{} = Countries.change_country(country)
    end

    test "create_country/1 with non alpha-3 country.code returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Countries.create_country(%{@valid_attrs | :code => "invalid code"})
    end

    test "update_country/2 with non alpha-3 country.code returns error changeset" do
      country = country_fixture()
      assert {:error, %Ecto.Changeset{}}  = Countries.update_country(country, %{@valid_attrs | :code => "invalid code"})
    end

    # test "cannot insert country without valid currency" do
    # test "cannot update country's currency once set"
      # would require all employee salaries to be converted. countries don't change their currencies. In such rare scenario, DB should be carefully updated using an external service rather than letting this happen via API.
    # test "removing currency affects countries referencing the currency"
      # how do I handle this?

  end
end
