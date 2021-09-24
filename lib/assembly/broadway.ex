defmodule Assembly.Broadway do
  use Broadway
  use Spandex.Decorators

  require Logger

  alias Assembly.{Build, Caster, ComponentCache}
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
  @decorate trace(service: :assembly, type: :function)
  def handle_message(_, %Message{data: data} = message, _context) do
    Logger.reset_metadata()

    bottle =
      data
      |> URI.decode()
      |> Bottle.Core.V1.Bottle.decode()

    Bottle.RequestId.read(:queue, bottle)

    with false <- from_self?(bottle),
         {:error, reason} <- notify_handler(bottle.resource) do
      Logger.error(inspect(reason))
    end

    message
  rescue
    e ->
      Logger.error(Exception.format(:error, e, __STACKTRACE__))
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

  def notify_handler({:build_created, %{build: build}}) do
    Logger.metadata(build_id: build.id)
    Logger.info("Handling Build Created message")

    with {:ok, updated_build} <- Build.create_build(Caster.cast(build)) do
      Build.emit_component_demands_for_build(to_string(updated_build.hal_id))
    end
  end

  def notify_handler({:build_updated, %{new: build}}) do
    Logger.metadata(build_id: build.id)
    Logger.info("Handling Build Updated message")

    case Build.get_build(build.id) do
      nil ->
        Logger.warn("Trying to update build that doesn't exist in local data")

      saved_build ->
        {:ok, updated_build} = Build.update_build(saved_build, Caster.cast(build))
        Build.emit_component_demands_for_build(to_string(updated_build.hal_id))
    end
  end

  def notify_handler({:build_picked, %{build: build}}) do
    Logger.metadata(build_id: build.id)
    Logger.info("Handling Build Picked message")

    # We delay here to ensure that the Warehouse service assigns the parts to
    # the build before anything else.
    Process.sleep(1000)

    case Build.pick_build(build.id) do
      {:ok, updated_build} ->
        Build.emit_component_demands_for_build(to_string(updated_build.hal_id))

      {:error, :not_found} ->
        Logger.warn("Trying to pick a build that doesn't exist in local data")
    end
  end

  def notify_handler({:component_availability_updated, availability_updated}) do
    %{component: %{id: component_id}, quantity: quantity} = availability_updated
    Logger.metadata(component_id: component_id)

    ComponentCache.put(component_id, quantity)
  end

  def notify_handler({event, message}) do
    Logger.warn("Ignoring #{event} message", resource: inspect(message))
    :ignored
  end

  def notify_handler(message) do
    Logger.error("Unable to handle unknown message", resource: inspect(message))
    :ignored
  end

  defp from_self?(%{source: @source}), do: true
  defp from_self?(_bottle), do: false
end
