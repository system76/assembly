defmodule Assembly.BuildTest do
  use Assembly.DataCase

  import Assembly.Factory

  alias Assembly.{Cache, Schemas.Build}

  describe "handle_cast/2" do
    test "determines build status and updates database if changed" do
      %{build: build} = build_component = insert(:build_component, component_id: 123, quantity: 1)
      Cache.update_quantity_available(123, 1)

      assert {:noreply, %{status: :ready}} =
               Assembly.Build.handle_cast(:determine_status, %{build | build_components: [build_component]})

      assert %{status: :ready} = Repo.get(Build, build.id)
    end
  end
end
