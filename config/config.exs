import Config

config :assembly,
  env: Mix.env(),
  ecto_repos: [Assembly.Repo],
  events: Assembly.Events,
  inventory_service_url: nil,
  producer: {BroadwayRabbitMQ.Producer, queue: "", connection: []},
  warmup: &Assembly.warmup/0

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :build_id, :component_id, :trace_id, :span_id, :resource],
  level: :info

config :logger_json, :backend,
  formatter: LoggerJSON.Formatters.DatadogLogger,
  metadata: :all

config :grpc, start_server: true

config :assembly, Assembly.Tracer,
  service: :assembly,
  adapter: SpandexDatadog.Adapter,
  disabled?: true

config :assembly, SpandexDatadog.ApiServer,
  batch_size: 2,
  http: HTTPoison,
  host: "127.0.0.1"

config :spandex, :decorators, tracer: Assembly.Tracer

import_config "#{Mix.env()}.exs"
