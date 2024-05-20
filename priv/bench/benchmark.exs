defmodule Exercise.Benchmark do
  @moduledoc """
  A Benchee based benchmarking module for Exercise implementation of
    - CRUD API
    - Batch writes
    - Metrics

  Note that this benchmark requires the DB to be populated with countries and currencies,
  ie run the seed script in 'priv/repo/seeds.exs' first.
  """

  require Logger
  alias Exercise.{Countries, Employees}

  def run() do
    setup()
    bench_employee_create()
    stop()
  end

  ## ==================================================================
  ## Benchmark scenarios

  # comparing various employee create operations
  def bench_employee_create() do
    # inserts
    # batch write
    # batch write unsafe
    Benchee.run(%{
      "batch_write/1" => fn inputs ->
        {:ok, _, []} = Employees.batch_write(inputs)
      end,

      "batch_write_unsafe/1" => fn inputs ->
        %{invalid_attr: []} = Employees.batch_write_unsafe(inputs)
      end
    },
    inputs: %{
      "10 employees" => generate_inputs_for_create(10),
      "1k employees" => generate_inputs_for_create(1_000),
      "10k employees" => generate_inputs_for_create(10_000),
      "100k employees" => generate_inputs_for_create(100_000),
    },
    before_scenario: fn input ->
      Employees.drop_employees()
      input
    end    ## clear table between scenarios
    )
  end

  def bench_fetch_metrics() do
    # get
    # cached read

    %{

    }
  end

  def bench_fetch_employee() do
    # read


  end

  ## ==================================================================
  ## Internal functions

  def setup() do
    Logger.configure(level: :warning)
    Application.ensure_all_started(:be_exercise)
  end

  def stop() do
    Application.stop(:be_exercise)
  end

  def generate_inputs_for_create(num_employees) do
    # fetch list of countries
    countries = Countries.list_countries()

    for _ <- 1..num_employees do
      generate_employee(countries)
    end
  end

  defp generate_employee(countries) do
    #generate employees
    full_name = random_str(10)
    job_title = random_str(10)
    salary = (5 * :rand.uniform(50)) * 1_000
    country = Enum.random(countries).id

    %{
      full_name: full_name,
      job_title: job_title,
      salary: salary,
      country_id: country
    }
  end

  defp random_str(length) do
    for _ <- 1..length, into: "", do: <<Enum.random(?a..?z)>>
  end
end

Exercise.Benchmark.run()
