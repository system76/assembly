defmodule Assembly.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Assembly.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Assembly.DataCase

      import Assembly.Factory
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Assembly.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Assembly.Repo, {:shared, self()})
    end

    :ok
  end
end
