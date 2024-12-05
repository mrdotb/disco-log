defmodule DiscoLog.Integrations.Phoenix do
  @moduledoc """
  Integration with Phoenix applications.

  ## How to use it

  It is a plug and play integration: as long as you have Phoenix installed the
  DiscoLog will receive and store the errors as they are reported.

  It also collects the exceptions that raise on your LiveView modules.

  ### How it works

  It works using Phoenix's Telemetry events, so you don't need to modify
  anything on your application.

  ### Errors on the Endpoint

  This integration only catches errors that raise after the requests hits your
  Router. That means that an exception on a plug defined on your Endpoint will
  not be reported.

  If you want to also catch those errors, we recommend you to set up the
  `ErrorTracker.Integrations.Plug` integration too.

  ### Default context

  For errors that are reported when executing regular HTTP requests (the ones
  that go to Controllers), the context added by default is the same that you
  can find on the `ErrorTracker.Integrations.Plug` integration.

  As for exceptions generated in LiveView processes, we collect some special
  information on the context:

  * `live_view.view`: the LiveView module itself,

  * `live_view.uri`: last URI that loaded the LiveView (available when the
  `handle_params` function is invoked).

  * `live_view.params`: the params received by the LiveView (available when the
  `handle_params` function is invoked).

  * `live_view.event`: last event received by the LiveView (available when the
  `handle_event` function is invoked).

  * `live_view.event_params`: last event params received by the LiveView
  (available when the `handle_event` function is invoked).
  """

  alias DiscoLog.Context
  alias DiscoLog.Integrations.Plug, as: PlugIntegration

  @events [
    # https://hexdocs.pm/phoenix/Phoenix.Logger.html#module-instrumentation
    [:phoenix, :router_dispatch, :start],
    [:phoenix, :router_dispatch, :exception],
    # https://hexdocs.pm/phoenix_live_view/telemetry.html
    [:phoenix, :live_view, :mount, :start],
    [:phoenix, :live_view, :mount, :exception],
    [:phoenix, :live_view, :handle_params, :start],
    [:phoenix, :live_view, :handle_params, :exception],
    [:phoenix, :live_view, :handle_event, :exception],
    [:phoenix, :live_view, :render, :exception],
    [:phoenix, :live_component, :update, :exception],
    [:phoenix, :live_component, :handle_event, :exception]
  ]

  @doc false
  def attach(config) do
    if Application.spec(:phoenix) do
      :telemetry.attach_many(__MODULE__, @events, &__MODULE__.handle_event/4, config)
    end
  end

  @doc false
  def handle_event([:phoenix, :router_dispatch, :start], _measurements, metadata, _config) do
    PlugIntegration.set_context(metadata.conn)
  end

  def handle_event([:phoenix, :router_dispatch, :exception], _measurements, metadata, config) do
    {reason, kind, stack} =
      case metadata do
        %{reason: %Plug.Conn.WrapperError{reason: reason, kind: kind, stack: stack}} ->
          {reason, kind, stack}

        %{kind: kind, reason: reason, stacktrace: stack} ->
          {reason, kind, stack}
      end

    PlugIntegration.report_error(metadata.conn, {kind, reason}, stack, config)
  end

  def handle_event([:phoenix, :live_view, :mount, :start], _, metadata, _config) do
    Context.set("live_view", %{
      "view" => metadata.socket.view
    })
  end

  def handle_event([:phoenix, :live_view, :handle_params, :start], _, metadata, _config) do
    Context.set("live_view", %{
      "uri" => metadata.uri,
      "params" => metadata.params
    })
  end

  def handle_event([:phoenix, :live_view, :handle_event, :exception], _, metadata, config) do
    context = %{
      "live_view" => %{
        "event" => metadata.event,
        "event_params" => metadata.event_params
      }
    }

    DiscoLog.report({metadata.kind, metadata.reason}, metadata.stacktrace, context, config)
  end

  def handle_event([:phoenix, :live_view, _action, :exception], _, metadata, config) do
    DiscoLog.report({metadata.kind, metadata.reason}, metadata.stacktrace, config)
  end

  def handle_event([:phoenix, :live_component, :update, :exception], _, metadata, config) do
    context = %{
      "live_view" => %{
        "component" => metadata.component
      }
    }

    DiscoLog.report({metadata.kind, metadata.reason}, metadata.stacktrace, context, config)
  end

  def handle_event(
        [:phoenix, :live_component, :handle_event, :exception],
        _,
        metadata,
        config
      ) do
    context = %{
      "live_view" => %{
        "component" => metadata.component,
        "event" => metadata.event,
        "event_params" => metadata.event_params
      }
    }

    DiscoLog.report({metadata.kind, metadata.reason}, metadata.stacktrace, context, config)
  end
end
