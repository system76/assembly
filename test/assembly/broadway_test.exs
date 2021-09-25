defmodule Assembly.BroadwayTest do
  use Assembly.DataCase

  import ExUnit.CaptureLog
  import Mox

  alias Assembly.Broadway

  setup :verify_on_exit!

  describe ":build_created" do
    test "runs without error" do
      stub(Assembly.MockEvents, :broadcast_build_update, fn _, _ -> :ok end)
      stub(Assembly.MockEvents, :broadcast_component_demand, fn _, _ -> :ok end)

      build = build(:bottle_build, build_components: build_list(2, :bottle_build_component))
      assert Broadway.notify_handler({:build_created, %{build: build}})
    end
  end

  describe ":build_updated" do
    test "updates build information" do
      stub(Assembly.MockEvents, :broadcast_build_update, fn _, _ -> :ok end)

      old_build = :build |> insert() |> supervise()
      new_build = build(:bottle_build)
      assert Broadway.notify_handler({:build_updated, %{old: old_build, new: new_build}})
    end

    test "logs message if build does not exist" do
      new_build = build(:bottle_build)

      assert capture_log(fn ->
               assert Broadway.notify_handler({:build_updated, %{old: nil, new: new_build}})
             end) =~ "Trying to update build that doesn't exist in local data"
    end
  end

  describe ":build_picked" do
    test "sets build status to picked" do
      stub(Assembly.MockEvents, :broadcast_build_update, fn _, _ -> :ok end)

      saved_build = :build |> insert() |> supervise()
      build = build(:bottle_build, id: saved_build.hal_id)
      assert Broadway.notify_handler({:build_picked, %{build: build}})
    end

    test "logs message if trying to pick a build that doesn't exist" do
      build = build(:bottle_build)

      assert capture_log(fn ->
               assert Broadway.notify_handler({:build_picked, %{build: build}})
             end) =~ "Trying to pick a build that doesn't exist in local data"
    end
  end

  describe ":component_availability_updated" do
    test "sets ComponentCache amount" do
      message = Bottle.Inventory.V1.ComponentAvailabilityUpdated.new(component: %{id: "ABC"}, quantity: 2)
      assert Broadway.notify_handler({:component_availability_updated, message})

      assert 2 == Assembly.ComponentCache.get("ABC")
    end
  end
end
