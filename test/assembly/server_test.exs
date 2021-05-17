defmodule Assembly.ServerTest do
  use GRPC.TestCase
  use Assembly.DataCase

  import Assembly.Factory
  import Mox

  alias Assembly.{Builds, Cache, MockEvents}
  alias Bottle.Assembly.V1.{BuildListRequest, BuildListResponse, Stub}

  setup :set_mox_from_context
  setup :verify_on_exit!

  describe "build_list/2" do
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
        {:ok, stream} = Stub.build_list(channel, BuildListRequest.new())

        assert {[%{id: ^build_one_id}], [%{id: ^build_two_id, missing_components: missing_components}]} =
                 stream
                 |> Enum.into([], fn {:ok, %BuildListResponse{build: build}} -> build end)
                 |> Enum.split_with(&(Map.get(&1, :status) == :BUILD_STATUS_READY))

        assert [%{component: %{id: "123"}, quantity: 1}] = missing_components
      end)

      Assembly.BuildSupervisor
      |> DynamicSupervisor.which_children()
      |> Enum.each(fn {_, pid, _type, _modules} -> DynamicSupervisor.terminate_child(Assembly.BuildSupervisor, pid) end)
    end
  end
end
