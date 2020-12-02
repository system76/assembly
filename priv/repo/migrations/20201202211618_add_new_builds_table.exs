defmodule Assembly.Repo.Migrations.AddNewBuildsTable do
  use Ecto.Migration

  def change do
    StatusEnum.create_type()

    create table(:builds) do
      add :hal_id, :integer, null: false
      add :status, StatusEnum.type()

      timestamps()
    end

    create table(:build_components) do
      add :build_id, references(:builds), null: false
      add :component_id, :integer, null: false
      add :quantity, :integer, default: 1
    end
  end
end
