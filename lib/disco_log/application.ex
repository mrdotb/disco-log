defmodule DiscoLog.Application do
  @moduledoc false

  use Application

  alias DiscoLog.Config
  alias DiscoLog.Integrations
  alias DiscoLog.LoggerHandler

  def start(_type, _args) do
    config = Config.read!()

    if config.enable do
      start_integration(config)

      children = [
        {DiscoLog.Supervisor, config}
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
    else
      Supervisor.start_link([], strategy: :one_for_one, name: __MODULE__)
    end
  end

  defp start_integration(config) do
    if config.enable_logger do
      :logger.add_handler(__MODULE__, LoggerHandler, %{config: config})
    end

    if config.instrument_oban do
      Integrations.Oban.attach(config)
    end

    if config.instrument_tesla do
      Integrations.Tesla.attach(config)
    end
  end
end
