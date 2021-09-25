defmodule Assembly.ComponentCacheTest do
  use Assembly.DataCase

  alias Assembly.ComponentCache

  describe "get/1" do
    test "returns 0 when value is unknown" do
      assert 0 == ComponentCache.get("NOPE")
    end

    test "returns cached amount" do
      Cachex.put(ComponentCache, "123", 4)
      assert 4 == ComponentCache.get("123")
    end
  end

  describe "put/2" do
    test "puts value in cache" do
      ComponentCache.put("432", 10)
      assert {:ok, 10} = Cachex.get(ComponentCache, "432")
    end
  end
end
