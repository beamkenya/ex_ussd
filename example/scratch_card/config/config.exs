use Mix.Config

config :scratch_card, port: System.get_env("PORT") || 8080

config :scratch_card, :gateway, AfricasTalking
