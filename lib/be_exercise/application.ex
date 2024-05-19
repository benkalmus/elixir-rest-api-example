defmodule Exercise.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @employee_metrics_cache :employee_metrics

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Exercise.Repo,
      # Start the Telemetry supervisor
      ExerciseWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Exercise.PubSub},
      # Start the Endpoint (http/https)
      ExerciseWeb.Endpoint,
      # Start the simple cache service for employee_metrics
      {Exercise.Services.SimpleCache, @employee_metrics_cache}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Exercise.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ExerciseWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
