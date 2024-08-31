defmodule DiscoLog.Integrations.Tesla do
  @moduledoc """
  Integration with Tesla

  ## How to use it

  Your tesla client must be configured to use the Tesla.Middleware.Telemetry

  ### How it works

  It works using Tesla's Telemetry events

  ### Default context

  The Tesla.Env struct is converted to a map and passed as context to the error report.

  read more on https://hexdocs.pm/tesla/Tesla.Middleware.Telemetry.html#module-telemetry-events
  """

  require Logger

  @events [
    [:tesla, :request, :exception]
  ]

  @doc false
  def attach(force_attachment \\ false) do
    if Application.spec(:tesla) || force_attachment do
      :telemetry.attach_many(__MODULE__, @events, &__MODULE__.handle_event/4, :no_config)
    end
  end

  def handle_event([:tesla, :request, :exception], _measurements, metadata, :no_config) do
    %{kind: kind, reason: reason, stacktrace: stacktrace, env: env} = metadata

    context = %{
      "tesla" => Map.from_struct(env)
    }

    DiscoLog.report({kind, reason}, stacktrace, context)
  end
end
