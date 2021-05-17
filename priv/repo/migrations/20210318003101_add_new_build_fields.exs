defmodule Assembly.Repo.Migrations.AddNewBuildFields do
  use Ecto.Migration

  def change do
    alter table(:builds) do
      add :model, :string, null: false
      add :order_id, :string, null: false
    end
  end
end
