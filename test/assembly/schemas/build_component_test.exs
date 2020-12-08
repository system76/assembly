defmodule Assembly.Schemas.BuildComponentTest do
  use Assembly.DataCase

  import Assembly.Factory

  alias Assembly.Schemas.{Build, BuildComponent}

  describe "changeset/2" do
    test "returns an invalid changeset if missing required field `build_id` or not valid database fkey" do
      %Build{id: build_id} = insert(:build)
      assert %{valid?: false} = BuildComponent.changeset(%BuildComponent{}, %{component_id: 1, quantity: 1})
      assert %{valid?: true} =
               BuildComponent.changeset(%BuildComponent{}, %{build_id: 999, component_id: 1, quantity: 1})

      assert %{valid?: true} =
               BuildComponent.changeset(%BuildComponent{}, %{build_id: build_id, component_id: 1, quantity: 1})
    end

    test "returns an invalid changeset if missing required field `component_id`" do
      %Build{id: build_id} = insert(:build)
      assert %{valid?: false} = BuildComponent.changeset(%BuildComponent{}, %{build_id: build_id, quantity: 1})

      assert %{valid?: true} =
               BuildComponent.changeset(%BuildComponent{}, %{build_id: build_id, component_id: 1, quantity: 1})
    end

    test "returns an invalid changeset if missing required field `quantity`" do
      %Build{id: build_id} = insert(:build)

      assert %{valid?: false} =
               BuildComponent.changeset(%BuildComponent{}, %{build_id: build_id, component_id: 1, quantity: nil})

      assert %{valid?: true} =
               BuildComponent.changeset(%BuildComponent{}, %{build_id: build_id, component_id: 1, quantity: 1})
    end
  end
end
