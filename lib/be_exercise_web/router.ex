defmodule ExerciseWeb.Router do
  use ExerciseWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ExerciseWeb do
    pipe_through :api

    # Currencies
    get "/currencies/code/:code", CurrencyController, :get_by_code

    # Employees
    post "/employees/batch_write", EmployeeController, :batch_write
    get "/employees/metrics_by_country", EmployeeController, :metrics_by_country
    get "/employees/metrics_by_job_title", EmployeeController, :metrics_by_job_title

    # Resources
    resources "/currencies", CurrencyController
    resources "/countries", CountryController
    resources "/employees", EmployeeController
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through [:fetch_session, :protect_from_forgery]
      live_dashboard "/dashboard", metrics: ExerciseWeb.Telemetry, ecto_repos: [Exercise.Repo]
    end
  end
end
