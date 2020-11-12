defmodule Assembly.Events do
  @moduledoc """
  Encapsulate resources in the message envelope and send via SQS
  """
  @callback send_event(atom(), struct()) :: ExAws.Operation.t()

  alias Bottle.Assembly.Events.V1.BuildUpdated
  alias Bottle.Inventory.V1.Component
  alias Bottle.Inventory.Events.V1.ComponentAvailabilityRequested

  def broadcast_build_update(build) do
    build_updated = BuildUpdated.new(build: build)
    send_event(:build_updated, build_updated)
  end

  def request_quantity_update(component_ids \\ []) do
    components = Enum.map(component_ids, &Component.new(id: &1))
    request = ComponentAvailabilityRequested.new(component: components)
    send_event(:component_availability_requested, request)
  end

  def send_event(type, resource) do
    bottled_message = encode(type, resource)

    type
    |> message_queue_url()
    |> ExAws.SQS.send_message(bottled_message)
    |> ExAws.request()
  end

  defp encode(type, resource) do
    args = [
      request_id: Keyword.get(Logger.metadata(), :request_id, nil),
      resource: {type, resource},
      source: "Assembly",
      timestamp: DateTime.to_unix(DateTime.utc_now())
    ]

    args
    |> Bottle.Core.V1.Bottle.new()
    |> Bottle.Core.V1.Bottle.encode()
    |> URI.encode()
  end

  defp message_queue_url(type) do
    :hal
    |> Application.get_env(:message_queues)
    |> Keyword.get(type)
  end
end
