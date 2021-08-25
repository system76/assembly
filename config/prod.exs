import Config

config :logger,
  backends: [LoggerJSON],
  level: :info

config :assembly, Assembly.Tracer, disabled?: false
