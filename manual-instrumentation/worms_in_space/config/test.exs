import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :worms_in_space, WormsInSpaceWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "vST4GnvQpBiyx3is3tTasQZCPZFY3Zi2dNo2T6M0LD5K95g5FgAlwtyJuVZ48INh",
  server: false

# In test we don't send emails.
config :worms_in_space, WormsInSpace.Mailer,
  adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
