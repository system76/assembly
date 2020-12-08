defmodule Assembly.CacheTest do
  use ExUnit.Case

  import Mox

  alias Assembly.{Cache, MockEvents}

  setup :verify_on_exit!

  describe "execute/1" do
    test "send a request for all component availability" do
      expect(
        MockEvents,
        :request_quantity_update,
        fn -> :ok end
      )

      Cache.execute(:ignored_state)
    end
  end

  describe "fallback/1" do
    test "send a request for a specific component's availability" do
      expect(
        MockEvents,
        :request_quantity_update,
        fn [1] -> :ok end
      )

      Cache.fallback(1)
    end
  end
end
