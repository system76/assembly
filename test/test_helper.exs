Mox.defmock(Assembly.MockEvents, for: Assembly.Events)

Ecto.Adapters.SQL.Sandbox.mode(Assembly.Repo, :manual)

{:ok, _} = Application.ensure_all_started(:ex_machina)

ExUnit.start()
