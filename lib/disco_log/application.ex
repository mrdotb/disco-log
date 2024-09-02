defmodule DiscoLog.Application do
  @moduledoc false

  use Application

  alias DiscoLog.Config
  alias DiscoLog.Dedupe
  alias DiscoLog.Integrations
  alias DiscoLog.LoggerHandler
  alias DiscoLog.Storage

  def start(_type, _args) do
    if Config.enabled?() do
      start_integration()

      children = [
        {Storage, []},
        {Dedupe, []}
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
    else
      Supervisor.start_link([], strategy: :one_for_one, name: __MODULE__)
    end
  end

  defp start_integration do
    if Config.logger_enabled?() do
      :logger.add_handler(:disco_log_handler, LoggerHandler, %{})
    end

    if Config.instrument_phoenix?() do
      Integrations.Phoenix.attach()
    end

    if Config.instrument_oban?() do
      Integrations.Oban.attach()
    end

    if Config.instrument_tesla?() do
      Integrations.Tesla.attach()
    end
  end
end
