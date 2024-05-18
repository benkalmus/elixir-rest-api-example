defmodule Exercise.Employees.Employee do
  use Ecto.Schema
  import Ecto.Changeset

  schema "employees" do
    field :full_name, :string
    field :job_title, :string
    field :salary,    :integer
    belongs_to :country, Exercise.Countries.Country, foreign_key: :country_id

    timestamps()
  end

  @doc false
  def changeset(employee, attrs) do
    employee
    |> cast(attrs, [:full_name, :job_title, :salary, :country_id])
    |> validate_required([:full_name, :job_title, :salary, :country_id])
    |> validate_number(:salary, greater_than: 0, message: "must be greater than 0")
    |> foreign_key_constraint(:country_id)
  end
end
