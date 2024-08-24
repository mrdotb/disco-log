defmodule DiscoLog.Application do
  @moduledoc false

  use Application

  alias DiscoLog.Config
  alias DiscoLog.Dedupe
  alias DiscoLog.Integrations
  alias DiscoLog.Storage

  def start(_type, _args) do
    # if Config.logger_enabled?() do
    #   DiscoLog.Logger.attach()
    # end

    # if Config.error_backend_enabled?() do
    #   Integrations.ErrorBackend.attach()
    # end

    if Config.instrument_phoenix?() do
      Integrations.Phoenix.attach()
    end

    if Config.instrument_oban?() do
      Integrations.Oban.attach()
    end

    children = [
      {Storage, []},
      {Dedupe, []}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end
end
