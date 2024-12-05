defmodule DiscoLog.Integrations.Oban do
  @moduledoc """
  Integration with Oban.

  ## How to use it

  It is a plug and play integration: as long as you have Oban installed the
  error will be reported.

  ### How it works

  It works using Oban's Telemetry events, so you don't need to modify anything
  on your application.

  ### Default context

  By default we store some context for you on errors generated in an Oban
  process:

  * `job.id`: the unique ID of the job.

  * `job.worker`: the name of the worker module.

  * `job.queue`: the name of the queue in which the job was inserted.

  * `job.args`: the arguments of the job being executed.

  * `job.priority`: the priority of the job.

  * `job.attempt`: the number of attempts performed for the job.
  """

  # https://hexdocs.pm/oban/Oban.Telemetry.html
  @events [
    [:oban, :job, :exception]
  ]

  @doc false
  def attach(config, force_attachment \\ false) do
    if Application.spec(:oban) || force_attachment do
      :telemetry.attach_many(__MODULE__, @events, &__MODULE__.handle_event/4, config)
    end
  end

  def handle_event([:oban, :job, :exception], _measurements, metadata, config) do
    %{reason: exception, stacktrace: stacktrace, job: job} = metadata
    state = Map.get(metadata, :state, :failure)

    context = %{
      "oban" => %{
        "args" => job.args,
        "attempt" => job.attempt,
        "id" => job.id,
        "priority" => job.priority,
        "queue" => job.queue,
        "worker" => job.worker,
        "state" => state
      }
    }

    stacktrace =
      if stacktrace == [],
        do: [{String.to_existing_atom("Elixir." <> job.worker), :perform, 2, []}],
        else: stacktrace

    DiscoLog.report(exception, stacktrace, context, config)
  end
end
