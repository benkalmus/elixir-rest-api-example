defmodule Exercise.Countries.Country do
  use Ecto.Schema
  import Ecto.Changeset

  schema "countries" do
    field :code, :string
    field :name, :string
    belongs_to :currency, Exercise.Countries.Currency, foreign_key: :currency_id
    has_many :employee, Exercise.Employees.Employee

    timestamps()
  end

  @doc false
  def changeset(country, attrs) do
    country
    |> cast(attrs, [:name, :code, :currency_id])
    |> validate_required([:name, :code, :currency_id])
    |> foreign_key_constraint(:currency_id)
    |> validate_length(:code, max: 3)
    |> unique_constraint(:name)
    |> unique_constraint(:code)
  end

  def delete_changeset(country) do
    country
    |> change()
    |> no_assoc_constraint(:employee, message: "country is associated with at least one employee")  # Ensures that countries can only be deleted if not associated with any records
  end
end
