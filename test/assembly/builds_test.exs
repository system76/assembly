defmodule Assembly.BuildsTest do
  use Assembly.DataCase

  import Assembly.Factory

  alias Assembly.{Builds, Cache, Schemas.Build}

  @moduletag capture_log: true

  def bottled_build do
    component = Bottle.Inventory.V1.Component.new(id: 123)
    build_component = Bottle.Assembly.V1.Build.BuildComponent.new(component: component, quantity: 1)
    Bottle.Assembly.V1.Build.new(id: 345, build_components: [build_component], status: :BUILD_STATUS_INCOMPLETE)
  end

  describe "new/1" do
    test "creates a new database record and starts GenServer" do
      %{active: active_count} = DynamicSupervisor.count_children(Assembly.BuildSupervisor)
      build = bottled_build()
      {:ok, pid} = Builds.new(build)

      assert [%{hal_id: 345}] = Repo.all(Build)
      %{active: new_active_count} = DynamicSupervisor.count_children(Assembly.BuildSupervisor)
      assert new_active_count == active_count + 1

      DynamicSupervisor.terminate_child(Assembly.BuildSupervisor, pid)
    end
  end

  describe "load_builds/0" do
    test "loads builds from database and starts GenServers" do
      insert_pair(:build)

      %{active: active_count} = DynamicSupervisor.count_children(Assembly.BuildSupervisor)
      Builds.load_builds()
      %{active: new_active_count} = DynamicSupervisor.count_children(Assembly.BuildSupervisor)

      assert new_active_count == active_count + 2

      Assembly.BuildSupervisor
      |> DynamicSupervisor.which_children()
      |> Enum.each(fn {_, pid, _type, _modules} -> DynamicSupervisor.terminate_child(Assembly.BuildSupervisor, pid) end)
    end
  end

  describe "recalculate_statues/0" do
    test "updates build status based on component availability" do
      %{build: build} = build_component = insert(:build_component, component_id: 123, quantity: 1)

      {:ok, pid} =
        DynamicSupervisor.start_child(
          Assembly.BuildSupervisor,
          {Assembly.Build, %{build | build_components: [build_component]}}
        )

      Cache.update_quantity_available(123, 1)
      Builds.recalculate_statues()

      Process.sleep(10)

      assert %{status: :ready} = Repo.get(Build, build.id)
      DynamicSupervisor.terminate_child(Assembly.BuildSupervisor, pid)
    end
  end
end
