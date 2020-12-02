defmodule Assembly.Endpoint do
  use GRPC.Endpoint

  intercept GRPC.Logger.Server
  run Assembly.Server
end
