defmodule Assembly.Server do
  use GRPC.Server, service: Bottle.Assembly.V1.Service

  alias Assembly.{Repo, Schemas}
  alias Bottle.Assembly.V1.{Build, BuildListRequest, BuildListResponse}

  @spec build_list(BuildListRequest.t(), GRPC.Server.Stream.t()) :: BuildListResponse.t()
  def build_list(_request, _stream) do
    builds =
      Schema.Build
      |> Repo.all()
      |> Enum.map(&bottled_build/1)

    BuildListResponse.new(builds: builds)
  end

  defp bottled_build(%Schemas.Build{hal_id: build_id, status: status}) do
    Build.new(id: build_id, status: protobuf_status(status))
  end

  defp protobuf_status(:built), do: :BUILD_STATUS_BUILT
  defp protobuf_status(:ready), do: :BUILD_STATUS_READY
  defp protobuf_status(_), do: :BUILD_STATUS_INCOMPLETE
end
