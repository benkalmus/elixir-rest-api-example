defmodule Exercise.Countries.Country do
  use Ecto.Schema
  import Ecto.Changeset

  schema "countries" do
    field :code, :string
    field :name, :string
    field :currency_id, :id

    timestamps()
  end

  @doc false
  def changeset(country, attrs) do
    country
    |> cast(attrs, [:name, :code, :currency_id])
    |> validate_required([:name, :code])
    |> validate_length(:code, max: 3)
    |> unique_constraint(:name)
    |> unique_constraint(:code)
  end
end
