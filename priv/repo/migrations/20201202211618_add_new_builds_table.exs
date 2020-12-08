defmodule Assembly.Repo.Migrations.AddNewBuildsTable do
  use Ecto.Migration

  def change do
    BuildStatusEnum.create_type()

    create table(:builds) do
      add :hal_id, :integer, null: false
      add :status, BuildStatusEnum.type()

      timestamps()
    end

    create table(:build_components) do
      add :build_id, references(:builds), null: false
      add :component_id, :integer, null: false
      add :quantity, :integer, null: false, default: 1
    end
  end
end
