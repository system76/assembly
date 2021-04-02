defmodule Assembly.BuildTest do
  use Assembly.DataCase

  import Assembly.Factory
  import Mox

  alias Assembly.{Build, Cache, MockEvents, Schemas}

  setup :verify_on_exit!

  describe "handle_cast/2" do
    test ":determine_status updates database if changed" do
      %{build: build} = build_component = insert(:build_component, component_id: "123", quantity: 1)
      Cache.update_quantity_available("123", 1)

      expect(MockEvents, :broadcast_build_update, fn _, _ -> :ok end)

      assert {:noreply, %{status: :ready}} =
               Build.handle_cast(:determine_status, %{build | build_components: [build_component]})

      assert %{status: :ready} = Repo.get(Schemas.Build, build.id)
    end
  end
end
