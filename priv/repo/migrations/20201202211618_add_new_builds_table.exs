defmodule Assembly.Repo.Migrations.AddNewBuildsTable do
  use Ecto.Migration

  def change do
    execute "CREATE TYPE status AS ENUM ('incomplete', 'ready', 'built');"

    create table(:builds, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :hal_id, :integer, null: false
      add :status, :status

      timestamps()
    end

    create table(:build_components, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :build_id, references(:builds, type: :uuid), null: false
      add :component_id, :integer, null: false
      add :quantity, :integer, null: false, default: 1

      timestamps()
    end
  end
end
