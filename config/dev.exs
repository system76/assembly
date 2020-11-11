use Mix.Config

config :assembly,
  producer: {Broadway.DummyProducer, []}

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :debug
