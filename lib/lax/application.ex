defmodule Lax.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LaxWeb.Telemetry,
      Lax.Repo,
      {DNSCluster, query: Application.get_env(:lax, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Lax.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Lax.Finch},
      # Task supervisor for sending pigeon push notifications async
      {Task.Supervisor, name: Lax.PigeonSupervisor},
      {Lynx.LinkPreview.Server,
       context_module: Lax.Messages, client: [strategy: Lynx.LinkPreview.OpenGraphClient]},
      # Start a worker by calling: Lax.Worker.start_link(arg)
      # {Lax.Worker, arg},
      # Start to serve requests, typically the last entry
      LaxWeb.Presence,
      LaxWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Lax.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LaxWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
