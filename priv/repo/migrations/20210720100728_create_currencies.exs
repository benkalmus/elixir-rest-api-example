defmodule Exercise.Repo.Migrations.CreateCurrencies do
  use Ecto.Migration

  def change do
    create table(:currencies) do
      add :code, :string, size: 3
      add :name, :string
      add :symbol, :string

      timestamps()
    end

    create unique_index(:currencies, [:code])
    create unique_index(:currencies, [:name])
  end
end
