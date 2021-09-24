defmodule Assembly.DataCase do
  use ExUnit.CaseTemplate

  import Mox, only: [set_mox_from_context: 1]

  using do
    quote do
      alias Assembly.Repo

      import Assembly.{DataCase, Factory}
      import Ecto
      import Ecto.{Changeset, Query}

      @moduletag capture_log: true
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Assembly.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Assembly.Repo, {:shared, self()})
    end

    on_exit(fn ->
      Assembly.BuildSupervisor
      |> DynamicSupervisor.which_children()
      |> Enum.map(fn {_, pid, _, _} -> pid end)
      |> Enum.map(fn pid -> DynamicSupervisor.terminate_child(Assembly.BuildSupervisor, pid) end)
    end)

    Cachex.clear(Assembly.ComponentCache)

    :ok
  end

  setup :set_mox_from_context
end
