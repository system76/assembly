defmodule Assembly.Demand do
  @moduledoc """
  This is a GenServer that handles emitting demand updates. It has a built in
  debounce, and a couple of other nifty features. It's called from other places
  in code when we need to generate new demand values and emit them to other
  services.
  """

  @timeout 30_000

  use GenServer

  alias Assembly.{Build, Option}

  def start_link(_) do
    GenServer.start_link(__MODULE__, name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok,
     %{
       timers: %{}
     }}
  end

  @doc """
  Iterates over all of the options attached to a build, and emits demand
  quantity for each of the components. This will use the starndard debounce.

  ## Examples

      iex> emit_build(id)
      :ok

  """
  @spec emit_build(String.t()) :: :ok | {:error, :not_found}
  def emit_build(build_id) do
    case Build.get_build(build_id) do
      nil ->
        {:error, :not_found}

      build ->
        build.options
        |> Enum.map(& &1.component_id)
        |> Enum.each(&emit_component/1)
    end
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

      _ ->
        {:noreply, state}
    end
  end
end
