defmodule Assembly.Schemas.BuildTest do
  use ExUnit.Case

  alias Assembly.Schemas.Build

  describe "changeset/2" do
    test "returns an invalid changeset if missing required field `hal_id`" do
      assert %{valid?: false} = Build.changeset(%Build{}, %{})
      assert %{valid?: true} = Build.changeset(%Build{}, %{hal_id: 123, model: "test", order_id: "1"})
    end
  end
end
