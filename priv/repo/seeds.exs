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

defmodule Exercise.Seed do
  @moduledoc """
  Elixir script to seed the database
  """
  alias Exercise.Countries
  # alias Exercise.Employees

  @insert_employees true
  @insert_countries true
  @job_title_subset_num 100
  @seed {1, 2, 3}
  @num_employees 10_000


  # Seed the 8 supported currencies
  # Euro (EUR)
  # UK Pound Sterling (GBP)
  # Australian Dollar (AUD)
  # New Zealand Dollar (NZD)
  # Unites States Dollar (USD)
  # Canadian Dollar (CAD)
  # Swiss Franc (CHF)
  # Japanese Yen (JPY)
  @currency_data [
    ["European Euro", "EUR", "€"],
    ["United Kingdom Pound Sterling", "GBP", "£"],
    ["Australian Dollar", "AUD", "$"],
    ["New Zealand Dollar", "NZD", "$"],
    ["United States Dollar", "USD", "$"],
    ["Canadian Dollar", "CAD", "$"],
    ["Swiss Franc", "CHF", "¥"],
    ["Japanese Yen", "JPY", "CHF"]
  ]

  # Seed the 12 supported countries
  @country_data [
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

  def generate_currencies() do
    for currency <- @currency_data do
      [name, code, symbol] = currency

      {:ok, _currency} =
        Countries.create_currency(%{
          name: name,
          code: code,
          symbol: symbol
        })
    end
  end

  def generate_countries(%{:countries => true}) do
    for country <- @country_data do
      [name, code, currency_code] = country
      currency = Countries.get_currency_by_code!(currency_code)
      country_map = %{
        name: name,
        code: code,
        currency_id: currency.id
      }

      IO.puts("INSERT:\n#{inspect(country_map)}\n")
      {:ok, _country} = Countries.create_country(country_map)

    end
    {:ok, :done}
  end
  def generate_countries(_) do
    {:ok, :skipped}
  end

  def generate_employees(%{:employees => true} = opts) do
    num_employees = opts[:number]
    IO.puts("Generating #{num_employees} employees\n")
    # read first and last names file
    first_names = File.stream!("priv/data/first_names.txt") |> Enum.to_list() |> Enum.map(&String.trim_trailing/1)
    last_names = File.stream!("priv/data/first_names.txt") |> Enum.to_list() |> Enum.map(&String.trim_trailing/1)
    job_titles = File.stream!("priv/data/job_titles.txt") |> Enum.to_list()

    #take subset of N job_titles
    job_titles = Enum.take_random(job_titles, @job_title_subset_num) |> Enum.map(&String.trim_trailing/1)

    country_ids = Countries.list_countries() |> Enum.map(fn c -> c.id end)

    employee_records = Enum.map(1..num_employees, fn _ -> Exercise.Seed.generate_employee(first_names, last_names, job_titles, country_ids) end)

    employee_records
      |> Enum.take_random(10)
      |> Enum.map(fn e ->
        IO.puts("INSERT:\n#{inspect(e)}\n")
      end)
  end
  def generate_employees(_) do
    {:ok, :skipped}
  end

  def generate_employee(first_names, last_names, job_titles, country_ids) do
    first_name = Enum.random(first_names)
    last_name = Enum.random(last_names)
    job_title = Enum.random(job_titles)
    country = Enum.random(country_ids)

    full_name = first_name <> " " <> last_name

    %{
      full_name: full_name,
      job_title: job_title,
      salary: gen_salary(),
      country_id: country
    }
  end

  #Returns a random integer in multiples of 5000, salary range is 5,000 up to 150,000
  defp gen_salary() do
    (5 * :rand.uniform(30)) * 1_000
  end

  def run(opts) do
    with {:ok, _} <- generate_countries(opts),
      {:ok, _} <- generate_employees(opts)
    do
      :ok
    end
  end

  defp parse_args(args) do
    options = [
      number: :integer,
      employees: :boolean,
      countries: :boolean,
      help: :boolean
    ]
    defaults = %{
      number: @num_employees,
      employees: @insert_employees,
      countries: @insert_countries
    }

    {opts, _, _} = OptionParser.parse(args, switches: options, aliases: [h: :help, n: :number, e: :employees, c: :countries])
    opts = Enum.into(opts, defaults)

    case opts[:help] do
      nil -> {:ok, opts}
      _ -> {:error, :show_help}
    end
  end

  defp print_usage() do
    IO.puts """
    Usage:
      seed.exs -n 100 -c=false [options]

    Options:
      -n, --number      NUMBER  Number of Employee records to generate & insert (default: #{@num_employees})
      -e, --employees   BOOL    If true, employees will be generated and inserted (default: #{@insert_employees})
      -c, --countries   BOOL    If true, currencies & countries will be inserted (default: #{@insert_countries})
      -h, --help                Print this help information
    """
  end

  # script entrypoint
  def main(args) do
    options = parse_args(args)

    #set random seed for reproducibility
    :rand.seed(:exsss, @seed)

    case options do
      {:error, _} ->
        print_usage()
      {:ok, opts} ->
        run(opts)
    end
  end
end

Exercise.Seed.main(System.argv())
