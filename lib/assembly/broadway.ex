defmodule Assembly.Broadway do
  use Broadway
  use Appsignal.Instrumentation.Decorators

  require Logger

  alias Assembly.{Builder, Components}
  alias Broadway.Message

  def start_link(_opts) do
    producer_module = Application.fetch_env!(:assembly, :producer)

    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: producer_module
      ],
      processors: [
        default: [concurrency: 2]
      ],
      batchers: [
        default: [
          batch_size: 10,
          batch_timeout: 2000
        ]
      ]
    )
  end

  @impl true
  @decorate transaction(:queue)
  def handle_message(_, %Message{} = message, _context) do
    %{resource: resource, request_id: request_id} =
      message
      |> URI.decode()
      |> Bottle.Core.V1.Bottle.decode()

    Logger.metadata(request_id: request_id)

    handle_resource(resource)

    message
  end

  @impl true
  def handle_batch(_, messages, _, _) do
    messages
  end

  @impl true
  def handle_failed([failed_message], _context) do
    [failed_message]
  end

  defp handle_resource({:build_created, %{build: build}}) do
    # TODO: Track build in DB
    DynamicSupervisor.start_child(Assembly.BuildSupervisor, {Assembly.Build, build})
    Builder.recalculate_statues()
  end

  defp handle_resource({:component_availability_updated, availability_updated}) do
    %{id: component_id} = availability_updated.component
    Components.update_quantity_available(component_id, availability_updated.quantity)
    Builder.recalculate_statues()
  end
end
