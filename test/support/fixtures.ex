defmodule Exercise.Fixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities
  """
  alias Exercise.Countries
  alias Exercise.Employees

  @doc """
  Generate a currency.
  """
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
  Generate a country given a valid currency_id.
  """
  def country_fixture(%{currency_id: _} = attrs) do
    # country must have a valid currency association
    {:ok, country} =
      attrs
      |> Enum.into(%{
        code: "CCC",
        name: "some country"
        })
      |> Countries.create_country()

    country
  end

  @doc """
  Generate an employee given a valid country_id.
  """
  def employee_fixture(%{country_id: _} = attrs) do
    {:ok, employee} =
      attrs
      |> Enum.into(%{
        full_name: "John Smith",
        job_title: "Software Engineer",
        salary: 50_000
        })
      |> Employees.create_employee()

    employee
  end

end
