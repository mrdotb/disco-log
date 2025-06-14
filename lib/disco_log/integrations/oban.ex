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

  > #### Universal Integration {: .tip}
  >
  > This integration will report errors directly to Discord, without logging it
  to other sources to avoid duplication. If you want to still log errors
  normally or if you use other error reporting libraries, you might want to
  roll out your own Oban instrumentation module that would work for all loggers. Here's an example:
  >
  > ```elixir
  > defmodule MyApp.ObanReporter do
  >   require Logger
  > 
  >   def attach do
  >     :telemetry.attach(:oban_errors, [:oban, :job, :exception], &__MODULE__.handle_event/4, [])
  >   end
  >   
  >   def handle_event([:oban, :job, :exception], _measure, meta, _) do
  >     job_meta = [
  >       attempt: meta.job.attempt,
  >       args: meta.job.args,
  >       id: meta.job.id,
  >       priority: meta.job.priority,
  >       queue: meta.job.queue,
  >       worker: meta.job.worker,
  >       state: meta.state,
  >       result: meta.result
  >     ]
  >       
  >     normalized = Exception.normalize(meta.kind, meta.reason, meta.stacktrace)
  >     reason = if kind == :throw, do: {:nocatch, reason}, else: normalized
  >       
  >     meta.kind
  >     |> Exception.format(meta.reason, meta.stacktrace)
  >     |> Logger.error(job_meta ++ [crash_reason: {normalized, meta.stacktrace})
  >   end
  > end
  > ```
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
    %{kind: kind, reason: reason, stacktrace: stacktrace, job: job} = metadata
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

    DiscoLog.report(kind, reason, stacktrace, context, config)
  end
end
