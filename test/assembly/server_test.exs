defmodule Assembly.ServerTest do
  use Assembly.GRPCTest
  use Assembly.DataCase

  import Mox

  alias Bottle.Assembly.V1.{
    GetBuildRequest,
    ListPickableBuildsRequest,
    ListComponentDemandsRequest,
    Stub
  }

  setup :verify_on_exit!

  describe "get_build/1" do
    test "returns data about a build", %{channel: channel} do
      build = :build |> insert() |> supervise()
      build_id = to_string(build.hal_id)
      Process.sleep(10)

      {:ok, response} = Stub.get_build(channel, GetBuildRequest.new(build: %{id: build_id}))

      assert %{id: ^build_id} = response.build
    end
  end

  describe "list_pickable_builds/2" do
    test "streams a list of ready and incomplete builds", %{channel: channel} do
      expect(Assembly.MockEvents, :broadcast_build_update, 4, fn _, _ -> :ok end)

      option = build(:option, build: nil, build_id: nil)
      4 |> insert_list(:build) |> supervise()
      4 |> insert_list(:build, options: [option]) |> supervise()

      Process.sleep(10)

      {:ok, stream} = Stub.list_pickable_builds(channel, ListPickableBuildsRequest.new())

      assert 8 == stream |> Enum.into([]) |> length()
    end
  end

  describe "list_component_demands/2" do
    test "streams a list of components and the demands", %{channel: channel} do
      option = build(:option, build: nil, build_id: nil, component_id: "ABC", quantity: 2)
      4 |> insert_list(:build, status: :incomplete, options: [option]) |> supervise()

      Process.sleep(10)

      {:ok, stream} = Stub.list_component_demands(channel, ListComponentDemandsRequest.new())

      assert [%{component_id: "ABC", demand_quantity: 8}] = Enum.into(stream, [], fn {:ok, res} -> res end)
    end
  end
end
