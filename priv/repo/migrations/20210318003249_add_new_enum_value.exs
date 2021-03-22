defmodule Assembly.Repo.Migrations.AddNewEnumValue do
  use Ecto.Migration

  @disable_ddl_transaction true

  def up do
    Ecto.Migration.execute("ALTER TYPE status ADD VALUE IF NOT EXISTS 'inprogress'")
  end

  def down do
  end
end
