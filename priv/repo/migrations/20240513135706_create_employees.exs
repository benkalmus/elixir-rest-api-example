defmodule Exercise.Repo.Migrations.CreateEmployees do
  use Ecto.Migration

  def change do
    create table(:employees) do
      add :full_name, :string
      add :job_title, :string
      add :salary,    :decimal, precision: 15, scale: 2, null: false
      add :country_id, references(:countries, on_delete: :restrict)

      timestamps()
    end

    create index(:employees, [:country_id])
    create index(:employees, [:job_title])
  end
end
