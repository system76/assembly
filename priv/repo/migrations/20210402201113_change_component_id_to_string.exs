defmodule Assembly.Repo.Migrations.RemoveHalIdFromBuilds do
  use Ecto.Migration

  def change do
    alter table(:build_components) do
      modify :component_id, :string 
    end
  end
end
