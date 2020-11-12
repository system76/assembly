defmodule Assembly.CacheTest do
  use ExUnit.Case

  import Mox

  alias Bottle.Inventory.Events.V1.ComponentAvailabilityRequested
  alias Bottle.Inventory.V1.Component

  setup :verify_on_exit!

  describe "execute/1" do
    test "send a request for all component availability" do
      expect(
        Assembly.MockEvents,
        :send_event,
        fn {:component_availability_requested, %ComponentAvailabilityRequested{component: []}} ->
          %ExAws.Operation{}
        end
      )

      Assembly.Cache.execute()
    end
  end

  describe "fallback/1" do
    test "send a request for a specific component's availability" do
      expect(
        Assembly.MockEvents,
        :send_event,
        fn {:component_availability_requested, %ComponentAvailabilityRequested{component: [%Component{id: 1}]}} ->
          %ExAws.Operation{}
        end
      )

      Assembly.Cache.fallback(1)
    end
  end
end
