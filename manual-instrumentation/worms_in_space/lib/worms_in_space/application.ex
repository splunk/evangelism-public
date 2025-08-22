defmodule WormsInSpace.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Setup OpenTelemetry instrumentations
    setup_opentelemetry()

    children = [
      # Start the Ecto repository
      WormsInSpace.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: WormsInSpace.PubSub},
      # Start the Endpoint (http/https)
      WormsInSpaceWeb.Endpoint
      # Start a worker by calling: WormsInSpace.Worker.start_link(arg)
      # {WormsInSpace.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WormsInSpace.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp setup_opentelemetry do
    # Setup OpenTelemetry SDK
    :opentelemetry_cowboy.setup()
    OpentelemetryPhoenix.setup(adapter: :cowboy2)
    OpentelemetryEcto.setup([:worms_in_space, :repo])
    OpentelemetryAbsinthe.setup()

    # Log initialization status
    if System.get_env("SPLUNK_ACCESS_TOKEN") do
      service_name = System.get_env("OTEL_SERVICE_NAME", "worms-in-space-backend")
      realm = System.get_env("SPLUNK_REALM", "us0")
      IO.puts("OpenTelemetry initialized for #{service_name} sending to Splunk #{realm}")
    else
      IO.puts("OpenTelemetry: No Splunk access token configured. Traces will not be sent.")
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WormsInSpaceWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
