use Mix.Config

config :assembly,
  producer: {Broadway.DummyProducer, []},
  events: Assembly.MockEvents
