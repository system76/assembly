defmodule Assembly.BuildTest do
  use Assembly.DataCase

  import Assembly.Factory
  import Mox

  alias Assembly.{Build, Cache, MockEvents, Schemas}

  setup :verify_on_exit!

  describe "handle_cast/2" do
    test ":determine_status does not change in progress build" do
      %{build: build} = build_component = insert(:build_component, component_id: "123", quantity: 3, build: build(:build, status: :inprogress))
      Cache.update_quantity_available("123", 1)

      expect(MockEvents, :broadcast_build_update, fn _, _ -> :ok end)

      assert {:noreply, %{status: :inprogress}} =
               Build.handle_cast(:determine_status, %{build | build_components: [build_component]})

      assert %{status: :inprogress} = Repo.get(Schemas.Build, build.id)
    end

    test ":determine_status updates database if changed" do
      %{build: build} = build_component = insert(:build_component, component_id: "123", quantity: 1)
      Cache.update_quantity_available("123", 1)

      expect(MockEvents, :broadcast_build_update, fn _, _ -> :ok end)

      assert {:noreply, %{status: :ready}} =
               Build.handle_cast(:determine_status, %{build | build_components: [build_component]})

      assert %{status: :ready} = Repo.get(Schemas.Build, build.id)
    end

    test ":determine_status updates missing component count" do
      %{build: build} = build_component = insert(:build_component, component_id: "123", quantity: 2)
      Cache.update_quantity_available("123", 1)

      expect(MockEvents, :broadcast_build_update, 0, fn _, _ -> :ok end)

      assert {:noreply, %{status: :incomplete, missing_components: [%{component_id: "123", quantity: 1}]}} =
               Build.handle_cast(:determine_status, %{build | build_components: [build_component]})
    end
  end
end
