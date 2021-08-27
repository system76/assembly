defmodule Assembly.ServerTest do
  use GRPC.TestCase, async: false
  use Assembly.DataCase, async: false

  import Assembly.Factory
  import Mox

  alias Assembly.{Builds, Cache, MockEvents}

  alias Bottle.Assembly.V1.{
    GetBuildRequest,
    ListPickableBuildsRequest,
    ListPickableBuildsResponse,
    ListComponentDemandsRequest,
    ListComponentDemandsResponse,
    Stub
  }

  setup :set_mox_from_context
  setup :verify_on_exit!

  describe "get_build/1" do
    test "returns data abouse a build" do
      %{build: build} = insert(:build_component, component_id: "321", quantity: 5)
      build_id = to_string(build.hal_id)

      Builds.start_builds()
      Process.sleep(10)

      run_server([Assembly.Server], fn port ->
        {:ok, channel} = GRPC.Stub.connect("localhost:#{port}")
        {:ok, response} = Stub.get_build(channel, GetBuildRequest.new(build: %{id: build_id}))

        assert %{id: ^build_id} = response.build
        assert [%{component: %{id: "321"}, quantity: 5}] = response.build.missing_components
      end)

      Assembly.BuildSupervisor
      |> DynamicSupervisor.which_children()
      |> Enum.each(fn {_, pid, _type, _modules} -> DynamicSupervisor.terminate_child(Assembly.BuildSupervisor, pid) end)
    end
  end

  describe "list_pickable_builds/2" do
    test "streams a list of ready and incomplete builds" do
      %{build: build_one} = insert(:build_component, component_id: "123", quantity: 1)
      %{build: build_two} = insert(:build_component, component_id: "123", quantity: 2)

      build_one_id = to_string(build_one.hal_id)
      build_two_id = to_string(build_two.hal_id)

      Cache.update_quantity_available("123", 1)

      expect(MockEvents, :broadcast_build_update, fn _, _ -> :ok end)

      Builds.start_builds()
      Process.sleep(10)

      run_server([Assembly.Server], fn port ->
        {:ok, channel} = GRPC.Stub.connect("localhost:#{port}")
        {:ok, stream} = Stub.list_pickable_builds(channel, ListPickableBuildsRequest.new())

        assert {[%{id: ^build_one_id}], [%{id: ^build_two_id, missing_components: missing_components}]} =
                 stream
                 |> Enum.into([], fn {:ok, %ListPickableBuildsResponse{build: build}} -> build end)
                 |> Enum.split_with(&(Map.get(&1, :status) == :BUILD_STATUS_READY))

        assert [%{component: %{id: "123"}, quantity: 1}] = missing_components
      end)

      Assembly.BuildSupervisor
      |> DynamicSupervisor.which_children()
      |> Enum.each(fn {_, pid, _type, _modules} -> DynamicSupervisor.terminate_child(Assembly.BuildSupervisor, pid) end)
    end
  end

  describe "list_component_demands/2" do
    test "streams a list of components and the demands" do
      insert(:build_component, component_id: "789", quantity: 6)
      insert(:build_component, component_id: "789", quantity: 4)
      insert(:build_component, component_id: "845", quantity: 21)

      Cache.update_quantity_available("789", 5)

      expect(MockEvents, :broadcast_build_update, fn _, _ -> :ok end)

      Builds.start_builds()
      Process.sleep(10)

      run_server([Assembly.Server], fn port ->
        {:ok, channel} = GRPC.Stub.connect("localhost:#{port}")
        {:ok, stream} = Stub.list_component_demands(channel, ListComponentDemandsRequest.new())

        assert [%{component_id: "789", demand_quantity: 10}, %{component_id: "845", demand_quantity: 21}] =
                 Enum.into(stream, [], fn {:ok, response} -> response end)
      end)

      Assembly.BuildSupervisor
      |> DynamicSupervisor.which_children()
      |> Enum.each(fn {_, pid, _type, _modules} -> DynamicSupervisor.terminate_child(Assembly.BuildSupervisor, pid) end)
    end
  end
end
