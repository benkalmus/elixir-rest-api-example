# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Exercise.Repo.insert!(%Exercise.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
#
# The code below demonstrates initial data insertion for currencies and countries.
# Please feel free to update the code if you consider it necessary.


alias Exercise.Countries

# Seed the 8 supported currencies
# Euro (EUR)
# UK Pound Sterling (GBP)
# Australian Dollar (AUD)
# New Zealand Dollar (NZD)
# Unites States Dollar (USD)
# Canadian Dollar (CAD)
# Swiss Franc (CHF)
# Japanese Yen (JPY)
currency_data = [
  ["European Euro", "EUR", "€"],
  ["United Kingdom Pound Sterling", "GBP", "£"],
  ["Australian Dollar", "AUD", "$"],
  ["New Zealand Dollar", "NZD", "$"],
  ["United States Dollar", "USD", "$"],
  ["Canadian Dollar", "CAD", "$"],
  ["Swiss Franc", "CHF", "¥"],
  ["Japanese Yen", "JPY", "CHF"]
]

for currency <- currency_data do
  [name, code, symbol] = currency

  {:ok, _currency} = Countries.create_currency(%{
    name: name,
    code: code,
    symbol: symbol
  })
end

# Seed the 12 supported countries
country_data = [
  ["Australia", "AUS", "AUD"],
  ["Canada", "CAN", "CAD"],
  ["France", "FRA", "EUR"],
  ["Japan", "JPN", "JPY"],
  ["Italy", "ITA", "EUR"],
  ["Liechtenstein", "LIE", "CHF"],
  ["New Zealand", "NZL", "NZD"],
  ["Portugal", "PRT", "EUR"],
  ["Spain", "ESP", "EUR"],
  ["Switzerland", "CHE", "CHF"],
  ["United Kingdom", "GBR", "GBP"],
  ["United States", "USA", "USD"]
]

currencies_map = Countries.list_currencies() |>
  Enum.reduce(%{}, fn c, acc -> Map.put(acc, c.code, c.id) end)

IO.puts("currencies are:\n#{inspect currencies_map}\n")

for country <- country_data do
  [name, code, currency_code] = country
  #fetch all currencies, form a hashmap
  currency = Countries.get_currency_by_code!(currency_code)
  # case currencies_map[currency_code] do
  #   nil ->
  #     #don't create country
  #     IO.puts("#{name}'s currency not found #{currency_code}\n")
  #     :ok
  #   id ->
    country_map = %{
      name: name,
      code: code,
      currency_id: currency.id
    }
    IO.puts("INSERT:\n#{inspect country_map}\n")
    {:ok, _country} = Countries.create_country(country_map)

  # end

end
