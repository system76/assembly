defmodule Assembly.Server do
  use GRPC.Server, service: Bottle.Assembly.V1.Service

  import Ecto.Query

  alias Assembly.{Repo, Schemas}
  alias Bottle.Assembly.V1.{Build, BuildListRequest, BuildListResponse}

  @spec build_list(BuildListRequest.t(), GRPC.Server.Stream.t()) :: any
  def build_list(_request, stream) do
    query =
      from b in Schemas.Build,
        where: b.status != :built

    query
    |> Repo.stream()
    |> stream_results(stream)
  end

  defp protobuf_status(:built), do: :BUILD_STATUS_BUILT
  defp protobuf_status(:inprogress), do: :BUILD_STATUS_INPROGRESS
  defp protobuf_status(:ready), do: :BUILD_STATUS_READY
  defp protobuf_status(_), do: :BUILD_STATUS_INCOMPLETE

  defp stream_results(repo, grpc_stream) do
    Repo.transaction(fn ->
      repo
      |> Stream.each(&stream_result(&1, grpc_stream))
      |> Stream.run()
    end)
  end

  defp stream_result(%Schemas.Build{hal_id: build_id, status: status}, stream) do
    build = Build.new(id: to_string(build_id), status: protobuf_status(status))
    response = BuildListResponse.new(build: build)
    GRPC.Server.send_reply(stream, response)
  end
end
