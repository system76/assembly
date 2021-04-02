defmodule Assembly.Schemas.BuildTest do
  use ExUnit.Case

  alias Assembly.Schemas.Build

  describe "changeset/2" do
    test "returns an invalid changeset if missing required field" do
      assert %{valid?: false} = Build.changeset(%Build{}, %{})
      assert %{valid?: true} = Build.changeset(%Build{}, %{model: "test", order_id: "1"})
    end
  end
end
