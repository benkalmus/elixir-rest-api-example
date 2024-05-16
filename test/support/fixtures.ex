defmodule Exercise.Fixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities
  """
  alias Exercise.Countries
  alias Exercise.Countries.{Country, Currency}
  alias Exercise.Employees
  alias Exercise.Employees.{Employee}

  @doc """
  Inserts a currency into DB with given attributes.
  """
  @spec currency_fixture(map()) :: %Currency{}
  def currency_fixture(attrs \\ %{}) do
    {:ok, currency} =
      attrs
      |> Enum.into(%{
        code: "ABC",
        name: "some currency",
        symbol: "$"
        })
      |> Countries.create_currency()

    currency
  end

  @doc """
  Inserts a country given a valid :currency_id into DB.
  """
  @spec country_fixture(%{currency_id: integer()}) :: %Country{}
  def country_fixture(%{currency_id: _} = attrs) do
    # country must have a valid currency association
    {:ok, country} =
      attrs
      |> Enum.into(%{
        code: "CCC",
        name: "some country"
        })
      |> Countries.create_country()

    Countries.preload(country)
  end

  @doc """
  Inserts an employee given a valid :country_id into DB.
  """
  @spec employee_fixture(map()) :: %Employee{}
  def employee_fixture(%{country_id: _} = attrs) do
    {:ok, employee} =
      attrs
      |> Enum.into(%{
        full_name: "John Smith",
        job_title: "Software Engineer",
        salary: Decimal.new("50000.00")
        })
      |> Employees.create_employee()

    Employees.preload(employee)
  end

end
