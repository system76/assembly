use Mix.Config

config :assembly,
  producer: {Broadway.DummyProducer, []},
  events: Assembly.MockEvents

onfig(:grpc, start_server: false)
