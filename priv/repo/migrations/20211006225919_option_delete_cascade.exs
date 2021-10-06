defmodule Assembly.Repo.Migrations.OptionDeleteCascade do
  use Ecto.Migration

  def change do
    execute """
    ALTER TABLE build_components DROP CONSTRAINT build_components_build_id_fkey
    """

    execute """
    ALTER TABLE build_components ADD CONSTRAINT build_components_build_id_fkey FOREIGN KEY (build_id) REFERENCES builds(id) ON DELETE CASCADE;
    """
  end
end
