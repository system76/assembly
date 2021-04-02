defmodule Assembly.Server do
  use GRPC.Server, service: Bottle.Assembly.V1.Service

  import Ecto.Query

  alias Assembly.{Caster, Repo, Schemas}
  alias Bottle.Assembly.V1.{BuildListRequest, BuildListResponse}

  @spec build_list(BuildListRequest.t(), GRPC.Server.Stream.t()) :: any
  def build_list(_request, stream) do
    query =
      from b in Schemas.Build,
        left_join: c in assoc(b, :build_components),
        where: b.status != :built,
        preload: [build_components: c]

    query
    |> Repo.all()
    |> stream_results(stream)
  end

  defp stream_results(results, grpc_stream) do
    results
    |> Stream.each(&stream_result(&1, grpc_stream))
    |> Stream.run()
  end

  defp stream_result(%Schemas.Build{} = build, stream) do
    build = Caster.cast(build)
    response = BuildListResponse.new(build: build)
    GRPC.Server.send_reply(stream, response)
  end
end
