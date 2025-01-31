defmodule Exercise.Repo.Migrations.CreateCountries do
  use Ecto.Migration

  def change do
    create table(:countries) do
      add :name, :string
      add :code, :string, size: 3
      add :currency_id, references(:currencies, on_delete: :restrict)

      timestamps()
    end

    create unique_index(:countries, [:name])
    create unique_index(:countries, [:code])
    create index(:countries, [:currency_id])
  end
end
