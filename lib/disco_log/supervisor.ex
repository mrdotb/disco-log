defmodule DiscoLog.Supervisor do
  @moduledoc """
  Supervisor that manages all processes required for logging. By default,
  `DiscoLog` starts it automatically, unless you use [advanced configuration](guides/advanced-configuration.md)
  """
  use Supervisor

  alias DiscoLog.Storage
  alias DiscoLog.Dedupe

  def child_spec(config) do
    Supervisor.child_spec(
      %{
        id: config.supervisor_name,
        start: {__MODULE__, :start_link, [config]},
        type: :supervisor
      },
      []
    )
  end

  @spec start_link(DiscoLog.Config.config()) :: Supervisor.on_start()
  def start_link(config) do
    callers = Process.get(:"$callers", [])
    Supervisor.start_link(__MODULE__, {config, callers}, name: config.supervisor_name)
  end

  @impl Supervisor
  def init({config, callers}) do
    children = [
      {Registry, keys: :unique, name: DiscoLog.Registry.registry_name(config.supervisor_name)},
      {Storage,
       supervisor_name: config.supervisor_name,
       discord_config: config.discord_config,
       discord: config.discord},
      {Dedupe, supervisor_name: config.supervisor_name}
    ]

    Process.put(:"$callers", callers)

    Supervisor.init(children, strategy: :one_for_one)
  end
end
