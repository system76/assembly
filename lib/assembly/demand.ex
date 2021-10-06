defmodule Assembly.Demand do
  @moduledoc """
  This is a GenServer that handles emitting demand updates. It has a built in
  debounce, and a couple of other nifty features. It's called from other places
  in code when we need to generate new demand values and emit them to other
  services.
  """

  @timeout 5_000

  use GenServer

  alias Assembly.{Build, Option}

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok,
     %{
       timers: %{}
     }}
  end

  @doc """
  Emits demand quantity for a component. This will use the standard debounce.

  ## Examples

      iex> emit_component(id)
      :ok

  """
  def emit_component(component_id) do
    GenServer.cast(__MODULE__, {:emit_component, component_id})
  end

  @impl true
  def handle_cast({:emit_component, component_id}, state) do
    uid = Ecto.UUID.generate()
    Process.send_after(self(), {:emit_component, uid, component_id}, @timeout)
    {:noreply, %{state | timers: Map.put(state.timers, component_id, uid)}}
  end

  @impl true
  def handle_info({:emit_component, uid, component_id}, state) do
    case Map.get(state.timers, component_id) do
      id when id == uid ->
        Option.emit_component_demands([component_id])
        {:noreply, %{state | timers: Map.delete(state.timers, component_id)}}

      _id ->
        {:noreply, state}
    end
  end
end
