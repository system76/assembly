defmodule Assembly.Server do
  use GRPC.Server, service: Bottle.Assembly.V1.Service

  require Logger

  alias Assembly.{Build, Caster, Schemas}

  alias Bottle.Assembly.V1.{
    GetBuildRequest,
    GetBuildResponse,
    ListPickableBuildsRequest,
    ListPickableBuildsResponse,
    ListComponentDemandsRequest,
    ListComponentDemandsResponse
  }

  @spec get_build(GetBuildRequest.t(), GRPC.Server.Stream.t()) :: GetBuildResponse.t()
  def get_build(request, _stream) do
    case Build.get_build(request.build.id) do
      nil ->
        raise GRPC.RPCError, status: :not_found

      build ->
        GetBuildResponse.new(request_id: Bottle.RequestId.write(:rpc), build: Caster.cast(build))
    end
  end

  @spec list_pickable_builds(ListPickableBuildsRequest.t(), GRPC.Server.Stream.t()) :: any
  def list_pickable_builds(_request, stream) do
    Build.list_builds()
    |> Stream.each(&stream_list_pickable_builds_result(&1, stream))
    |> Stream.run()
  end

  defp stream_list_pickable_builds_result(%Schemas.Build{} = build, stream) do
    build = Caster.cast(build)
    response = ListPickableBuildsResponse.new(request_id: Bottle.RequestId.write(:rpc), build: build)
    GRPC.Server.send_reply(stream, response)
  end

  @spec list_component_demands(ListComponentDemandsRequest.t(), GRPC.Server.Stream.t()) :: any
  def list_component_demands(_request, stream) do
    Build.get_component_demands()
    |> Enum.each(&stream_list_component_demands_result(&1, stream))
  end

  defp stream_list_component_demands_result({component_id, quantity}, stream) do
    response =
      ListComponentDemandsResponse.new(
        request_id: Bottle.RequestId.write(:rpc),
        component_id: component_id,
        demand_quantity: quantity
      )

    GRPC.Server.send_reply(stream, response)
  end
end
