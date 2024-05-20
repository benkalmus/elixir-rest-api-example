defmodule Exercise.Services.SimpleCacheSup do
  use Supervisor

  alias Exercise.Services.SimpleCache

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_) do
    children = [
      # Spawn a simple cache instance for employee metrics data
      {SimpleCache, employee_metrics_cache()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  # Return name of the Employee Metrics cache
  @spec employee_metrics_cache() :: :employee_metrics_cache
  def employee_metrics_cache() do
    :employee_metrics_cache
  end
end
