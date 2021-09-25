defmodule Assembly.Schemas.OptionTest do
  use Assembly.DataCase

  import Assembly.Factory

  alias Assembly.Schemas.{Build, Option}

  describe "changeset/2" do
    test "returns an invalid changeset if missing required field `component_id`" do
      %Build{id: build_id} = insert(:build)
      assert %{valid?: false} = Option.changeset(%Option{}, %{build_id: build_id, quantity: 1})

      assert %{valid?: true} = Option.changeset(%Option{}, %{build_id: build_id, component_id: "1", quantity: 1})
    end

    test "returns an invalid changeset if missing required field `quantity`" do
      %Build{id: build_id} = insert(:build)

      assert %{valid?: false} = Option.changeset(%Option{}, %{build_id: build_id, component_id: "1", quantity: nil})

      assert %{valid?: true} = Option.changeset(%Option{}, %{build_id: build_id, component_id: "1", quantity: 1})
    end
  end
end
