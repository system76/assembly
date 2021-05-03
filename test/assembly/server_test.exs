defmodule Assembly.ServerTest do
  use GRPC.TestCase
  use Assembly.DataCase

  import Assembly.Factory

  alias Bottle.Assembly.V1.{BuildListRequest, BuildListResponse, Stub}

  describe "build_list/2" do
    test "streams a list of ready and incomplete builds" do
      %{hal_id: build_one} = insert(:build, status: :ready)
      %{hal_id: build_two} = insert(:build, status: :incomplete)
      %{hal_id: build_three} = insert(:build, status: :built)

      run_server([Assembly.Server], fn port ->
        {:ok, channel} = GRPC.Stub.connect("localhost:#{port}")
        {:ok, stream} = Stub.build_list(channel, BuildListRequest.new())

        build_ids =
          Enum.into(stream, [], fn {:ok, %BuildListResponse{build: %{id: build_id}}} ->
            build_id
          end)

        assert to_string(build_one) in build_ids
        assert to_string(build_two) in build_ids
        refute to_string(build_three) in build_ids
      end)
    end
  end
end
