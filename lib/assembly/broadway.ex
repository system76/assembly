defmodule Assembly.Broadway do
  use Broadway
  use Appsignal.Instrumentation.Decorators

  require Logger

  alias Assembly.{Builds, Cache}
  alias Broadway.Message

  @source "assembly"

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
  def handle_message(_, %Message{data: data} = message, _context) do
    bottle =
      data
      |> URI.decode()
      |> Bottle.Core.V1.Bottle.decode()

    Bottle.RequestId.read(:queue, bottle)

    with false <- from_self?(bottle),
         {:error, reason} <- notify_handler(bottle.resource) do
      Logger.error(reason)
    end

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

  defp notify_handler({:build_created, %{build: build}}) do
    Logger.info("Handling Build Created message")
    Builds.new(build)
  end

  defp notify_handler({:build_updated, %{new: build}}) do
    Logger.info("Handling Build Updated message")
    Builds.update(build)
  end

  defp notify_handler({:component_availability_updated, availability_updated}) do
    %{id: component_id} = availability_updated.component
    Cache.update_quantity_available(component_id, availability_updated.quantity)
  end

  defp from_self?(%{source: @source}), do: true
  defp from_self?(_bottle), do: false
end
