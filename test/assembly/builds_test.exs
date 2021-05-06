defmodule Assembly.BuildsTest do
  use Assembly.DataCase

  import Assembly.Factory
  import Mox

  alias Assembly.{Builds, Cache, MockEvents, Schemas.Build}

  setup :set_mox_from_context
  setup :verify_on_exit!

  @component_id "123"
  @moduletag capture_log: true

  def bottled_build do
    component = Bottle.Inventory.V1.Component.new(id: @component_id)
    order = Bottle.Fulfillment.V1.Order.new(id: 123)
    build_component = Bottle.Assembly.V1.Build.BuildComponent.new(component: component, quantity: 1)

    Bottle.Assembly.V1.Build.new(
      id: 345,
      build_components: [build_component],
      model: "test",
      order: order,
      status: :BUILD_STATUS_INCOMPLETE
    )
  end

  describe "new/1" do
    test "creates a new database record and starts GenServer" do
      %{active: active_count} = DynamicSupervisor.count_children(Assembly.BuildSupervisor)
      build = bottled_build()
      {:ok, pid} = Builds.new(build)

      assert [%{build_components: [%{component_id: @component_id}]}] =
               Build
               |> Repo.all()
               |> Repo.preload(:build_components)

      %{active: new_active_count} = DynamicSupervisor.count_children(Assembly.BuildSupervisor)
      assert new_active_count == active_count + 1

      DynamicSupervisor.terminate_child(Assembly.BuildSupervisor, pid)
    end
  end

  describe "start_builds/0" do
    test "loads builds from database and starts GenServers" do
      insert_pair(:build)

      %{active: active_count} = DynamicSupervisor.count_children(Assembly.BuildSupervisor)
      Builds.start_builds()
      %{active: new_active_count} = DynamicSupervisor.count_children(Assembly.BuildSupervisor)

      assert new_active_count == active_count + 2

      Assembly.BuildSupervisor
      |> DynamicSupervisor.which_children()
      |> Enum.each(fn {_, pid, _type, _modules} -> DynamicSupervisor.terminate_child(Assembly.BuildSupervisor, pid) end)
    end
  end

  describe "recalculate_statues/0" do
    test "updates build status based on component availability" do
      %{build: build} = insert(:build_component, component_id: @component_id, quantity: 1)

      expect(MockEvents, :broadcast_build_update, fn _, _ -> :ok end)

      Builds.start_builds()

      Cache.update_quantity_available(@component_id, 1)

      Builds.recalculate_statues()

      Process.sleep(10)

      assert %{status: :ready} = Repo.get(Build, build.id)

      Assembly.BuildSupervisor
      |> DynamicSupervisor.which_children()
      |> Enum.each(fn {_, pid, _type, _modules} -> DynamicSupervisor.terminate_child(Assembly.BuildSupervisor, pid) end)
    end
  end
end
