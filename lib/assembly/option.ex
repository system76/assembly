defmodule Assembly.Option do
  @moduledoc """
  Helper functions for handling options.
  """

  alias Assembly.{ComponentCache, Schemas}

  @doc """
  Returns a list of `Assembly.Schemas.Option` that we do not have enough
  quantity for.

  ## Examples

      iex> unavailable_options([%Schemas.Option{}])
      []

  """
  @spec unavailable_options([Schemas.Option]) :: [Schemas.Option]
  def unavailable_options(options) do
    Enum.reject(options, &(ComponentCache.get(&1.component_id) >= &1.quantity))
  end
end
