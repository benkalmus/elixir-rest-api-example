defmodule Exercise.Countries.Currency do
  use Ecto.Schema
  import Ecto.Changeset

  alias Exercise.Services.CurrencyConverter

  schema "currencies" do
    field :code, :string
    field :name, :string
    field :symbol, :string
    has_many :country, Exercise.Countries.Country

    timestamps()
  end

  @doc false
  def changeset(currency, attrs) do
    currency
    |> cast(attrs, [:code, :name, :symbol])
    |> validate_required([:code, :name, :symbol])
    |> validate_length(:code, max: 3)
    |> validate_inclusion(:code, CurrencyConverter.supported_currency_codes())
    |> no_assoc_constraint(:country)
    |> unique_constraint(:name)
    |> unique_constraint(:code)
  end

  # Checks if currency can be deleted (no associated country)
  def delete_changeset(currency) do
    currency
    |> change()
    # Ensures that currency can only be delete if it is not associated with any country
    |> no_assoc_constraint(:country, message: "currency is associated with a country")
  end
end
