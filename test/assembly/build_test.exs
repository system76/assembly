defmodule Assembly.BuildsTest do
  use Assembly.DataCase

  import Mox

  alias Assembly.{AdditiveMap, Build, Repo, Schemas}

  setup :verify_on_exit!

  describe "list_builds/0" do
    test "lists all running builds" do
      stub(Assembly.MockEvents, :broadcast_build_update, fn _, _ -> :ok end)

      3 |> build_list(:build) |> supervise()

      assert 3 == Build.list_builds() |> length()
    end
  end

  describe "get_build/1" do
    test "returns build information from hal_id" do
      stub(Assembly.MockEvents, :broadcast_build_update, fn _, _ -> :ok end)

      db_build = :build |> insert() |> supervise()

      build = Build.get_build(db_build.hal_id)
      assert build.id == db_build.id
    end

    test "returns nil if build GenServer is not started" do
      db_build = insert(:build)
      refute Build.get_build(db_build.hal_id)
    end
  end

  describe "create_build/1" do
    test "inserts record into db with valid data" do
      stub(Assembly.MockEvents, :broadcast_build_update, fn _, _ -> :ok end)

      attrs = params_for(:build, options: build_list(2, :option))
      assert {:ok, build} = Build.create_build(attrs)

      assert Repo.get(Schemas.Build, build.id)
    end

    test "starts GenServer with valid data" do
      stub(Assembly.MockEvents, :broadcast_build_update, fn _, _ -> :ok end)

      attrs = params_with_assocs(:build, options: build_list(4, :option))
      assert {:ok, build} = Build.create_build(attrs)

      assert 1 == Assembly.BuildRegistry |> Registry.lookup(to_string(build.hal_id)) |> length()
    end

    test "returns ecto changeset on error" do
      attrs = params_for(:build, hal_id: nil, order_id: nil)
      assert {:error, _changeset} = Build.create_build(attrs)
    end
  end

  describe "update_build/2" do
    test "updates the database record with valid data" do
      expect(Assembly.MockEvents, :broadcast_build_update, fn _, _ -> :ok end)

      build = :build |> insert(options: []) |> supervise()
      %{component_id: cid} = option = params_with_assocs(:option) |> Map.drop([:build_id])

      assert {:ok, build} = Build.update_build(build, %{options: [option]})

      Process.sleep(10)

      assert %{component_id: ^cid} = Repo.get_by(Schemas.Option, build_id: build.id)
    end

    test "updates GenServer with valid data" do
      expect(Assembly.MockEvents, :broadcast_build_update, 2, fn _, _ -> :ok end)

      build = :build |> insert(status: :ready, options: []) |> supervise()
      option = params_with_assocs(:option) |> Map.drop([:build_id])
      assert {:ok, build} = Build.update_build(build, %{options: [option]})

      Process.sleep(10)

      [{pid, _}] = Registry.lookup(Assembly.BuildRegistry, to_string(build.hal_id))
      demand = GenServer.call(pid, :get_demand)
      assert 1 == AdditiveMap.get(demand, option.component_id)
    end

    test "is a no-op if no data changes" do
      build = :build |> insert() |> supervise()
      assert {:ok, build} == Build.update_build(build, %{})
    end

    test "returns ecto changeset on error" do
      build = :build |> insert() |> supervise()
      assert {:error, _changeset} = Build.update_build(build, %{status: :nope})
    end
  end

  describe "pick_build/1" do
    test "sets the build status to inprogress" do
      expect(Assembly.MockEvents, :broadcast_build_update, fn _, _ -> :ok end)

      build = :build |> insert(status: :ready) |> supervise()
      assert {:ok, build} = Build.pick_build(build.hal_id)

      Process.sleep(10)

      updated_build = Build.get_build(build.hal_id)
      assert :inprogress == updated_build.status
    end

    test "returns not found error if build is not pickable" do
      assert {:error, :not_found} = Build.pick_build("nope")
    end
  end

  describe "get_component_demands/0" do
    test "merges demand from every build" do
      stub(Assembly.MockEvents, :broadcast_build_update, fn _, _ -> :ok end)

      option_one = build(:option, build: nil, build_id: nil, component_id: "1", quantity: 2)
      option_two = build(:option, build: nil, build_id: nil, component_id: "2", quantity: 1)
      2 |> insert_list(:build, options: [option_one, option_two]) |> supervise()

      Process.sleep(10)

      demand = Build.get_component_demands()
      assert 4 == AdditiveMap.get(demand, option_one.component_id)
      assert 2 == AdditiveMap.get(demand, option_two.component_id)
    end
  end
end
