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
  alias Exercise.Employees

  @insert_employees true
  @insert_countries true
  @insert_currencies true
  @job_title_subset_num 100
  @seed {1, 2, 3}
  #number of employees to insert in a single request to batch_write
  @batch_size 10000
  @num_employees 10_000 #TODO


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

  def generate_currencies(%{:countries => true}) do
    IO.puts("\nInserting currencies\n")
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
  def generate_currencies(_) do
    {:ok, :skipped}
  end

  def generate_countries(%{:countries => true}) do
    IO.puts("\nInserting countries\n")
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
    IO.puts("\nInserting employees #{num_employees}\n")
    # read first and last names file
    first_names = File.stream!("priv/data/first_names.txt") |> Enum.to_list() |> Enum.map(&String.trim_trailing/1)
    last_names = File.stream!("priv/data/first_names.txt") |> Enum.to_list() |> Enum.map(&String.trim_trailing/1)
    job_titles = File.stream!("priv/data/job_titles.txt") |> Enum.to_list()

    #take subset of N job_titles
    job_titles = Enum.take_random(job_titles, @job_title_subset_num) |> Enum.map(&String.trim_trailing/1)

    #retrieve all country ids
    country_ids = Countries.list_countries() |> Enum.map(fn c -> c.id end)

    employee_records = Enum.map(1..num_employees, fn _ -> Exercise.Seed.generate_employee(first_names, last_names, job_titles, country_ids) end)
    # print out first 5 employees
    employee_records |> Enum.take(5) |> Enum.map(fn e ->
        IO.puts("INSERT:\n#{inspect(e)}\n")
      end)
    IO.puts("Generated #{length(employee_records)} employees\n")
    insert_employees(employee_records)
    num_inserted = length(Employees.list_employees())
    IO.puts("Inserted #{num_inserted} employees\n")
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

  def insert_employees(employees) do
    # split employees into N batches and post them to batch_write
    employees
      |> Enum.chunk_every(@batch_size)
      |> Enum.each(&Employees.batch_write_unsafe/1)
  end

  #Returns a random integer in multiples of 5000, salary range is 5,000 up to 150,000
  defp gen_salary() do
    (5 * :rand.uniform(30)) * 1_000
  end

  def run(opts) do
    generate_currencies(opts)
    generate_countries(opts)
    generate_employees(opts)
  end

  defp parse_args(args) do
    options = [
      number: :integer,
      employees: :boolean,
      countries: :boolean,
      currencies: :boolean,
      help: :boolean
    ]
    defaults = %{
      number: @num_employees,
      employees: @insert_employees,
      countries: @insert_countries,
      currencies: @insert_currencies
    }

    {opts, _, _} = OptionParser.parse(args, switches: options, aliases: [h: :help, n: :number, e: :employees, c: :countries, o: :currencies])
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
      -c, --countries   BOOL    If true, countries will be inserted (default: #{@insert_countries})
      -o, --currencies  BOOL    If true, currencies will be inserted (default: #{@insert_currencies})
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
