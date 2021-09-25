defmodule Assembly.OptionTest do
  use Assembly.DataCase

  alias Assembly.{ComponentCache, Option}

  describe "unavailable_components/1" do
    test "returns all build components if we have an empty cache" do
      options = build_list(4, :option)
      assert options == Option.unavailable_options(options)
    end

    test "returns accurate list of components not available" do
      available_options = build_list(2, :option, quantity: 2)
      unavailable_options = build_list(2, :option)

      Enum.each(available_options, &ComponentCache.put(&1.component_id, 2))

      assert unavailable_options == Option.unavailable_options(available_options ++ unavailable_options)
    end

    test "takes into account the quantity when getting unavailable options" do
      option = build(:option, quantity: 2)
      ComponentCache.put(option.component_id, 1)
      assert [option] == Option.unavailable_options([option])
    end
  end
end
