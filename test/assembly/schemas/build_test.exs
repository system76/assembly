defmodule Assembly.Schemas.BuildTest do
  use Assembly.DataCase

  alias Assembly.Schemas.Build

  describe "changeset/2" do
    test "returns an invalid changeset if missing required field" do
      assert %{valid?: false} = Build.changeset(%Build{}, %{})
      assert %{valid?: true} = Build.changeset(%Build{}, %{hal_id: "1", model: "test", order_id: "1"})
    end

    test "ignores options that are out of order but similar" do
      option = build(:option)
      build = build(:build, options: [option])

      changeset =
        Build.changeset(build, %{
          "options" => [
            %{"component_id" => option.component_id, "quantity" => option.quantity}
          ]
        })

      assert %{} == changeset.changes
    end

    test "updates quantity for options" do
      option = build(:option, quantity: 3)
      build = build(:build, options: [option])

      changeset =
        Build.changeset(build, %{
          "options" => [
            %{"component_id" => option.component_id, "quantity" => 2}
          ]
        })

      assert %{quantity: 2} == hd(changeset.changes.options).changes
    end

    test "updates multiple options" do
      option = build(:option)
      build = build(:build, options: [option])

      changeset =
        Build.changeset(build, %{
          "options" => [
            %{"component_id" => option.component_id, "quantity" => option.quantity},
            %{"component_id" => option.component_id, "quantity" => 6},
            %{"component_id" => "12345", "quantity" => 2},
            %{"component_id" => "1421", "quantity" => 2}
          ]
        })

      assert [:update, :insert, :insert, :insert] ==
               Enum.map(changeset.changes.options, & &1.action)
    end
  end
end
