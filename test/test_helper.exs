ExUnit.start()

{:ok, _} = Application.ensure_all_started(:ex_machina)

Ecto.Adapters.SQL.Sandbox.mode(Assembly.InventoryRepo, :manual)
Ecto.Adapters.SQL.Sandbox.mode(Assembly.Repo, :manual)
