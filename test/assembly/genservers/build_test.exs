defmodule Assembly.GenServers.BuildTest do
  use Assembly.DataCase

  import Mox

  alias Assembly.AdditiveMap
  alias Assembly.GenServers.Build

  setup :verify_on_exit!

  describe ":get_info" do
    test "returns data for build" do
      build = insert(:build, options: build_list(4, :option))
      {:ok, pid} = start_supervised({Build, build})
      assert build == GenServer.call(pid, :get_info)
    end
  end

  describe ":get_demand" do
    test "returns quantity of component demand" do
      option_one = build(:option, component_id: "A", quantity: 4)
      option_two = build(:option, component_id: "B", quantity: 2)
      build = insert(:build, options: [option_one, option_two])
      {:ok, pid} = start_supervised({Build, build})

      demand = GenServer.call(pid, :get_demand)
      assert 4 == AdditiveMap.get(demand, option_one.component_id)
      assert 2 == AdditiveMap.get(demand, option_two.component_id)
    end
  end

  describe ":update_build" do
    test "with status built stops genserver" do
      expect(Assembly.MockEvents, :broadcast_build_update, fn _, _ -> :ok end)

      build = insert(:build, options: [], status: :incomplete)
      {:ok, pid} = start_supervised({Build, build})

      GenServer.cast(pid, {:update_build, %{build | status: :built}})
      Process.sleep(10)

      refute Process.alive?(pid)
    end

    test "data field updates set the internal data" do
      expect(Assembly.MockEvents, :broadcast_build_update, fn _, _ -> :ok end)

      build = insert(:build, model: "old", options: [], status: :incomplete)
      {:ok, pid} = start_supervised({Build, build})

      assert :ok == GenServer.cast(pid, {:update_build, %{build | model: "new"}})
      new_build = GenServer.call(pid, :get_info)
      assert "new" == new_build.model
    end

    test "build with no options is set to ready status" do
      expect(Assembly.MockEvents, :broadcast_build_update, fn _, _ -> :ok end)

      build = insert(:build, options: [], status: :incomplete)
      {:ok, pid} = start_supervised({Build, build})

      Process.sleep(10)

      new_build = GenServer.call(pid, :get_info)
      assert :ready == new_build.status
    end

    test "build with options with unavailable quantity sets status to incomplete" do
      expect(Assembly.MockEvents, :broadcast_build_update, fn _, _ -> :ok end)

      option = build(:option)
      build = insert(:build, options: [option], status: :ready)
      {:ok, pid} = start_supervised({Build, build})

      Process.sleep(10)

      new_build = GenServer.call(pid, :get_info)
      assert :incomplete == new_build.status
    end

    test "build with options with available quantity sets status to ready" do
      expect(Assembly.MockEvents, :broadcast_build_update, fn _, _ -> :ok end)

      option = build(:option)
      Assembly.ComponentCache.put(option.component_id, 1)
      build = insert(:build, options: [option], status: :incomplete)
      {:ok, pid} = start_supervised({Build, build})

      Process.sleep(10)

      new_build = GenServer.call(pid, :get_info)
      assert :ready == new_build.status
    end
  end
end
