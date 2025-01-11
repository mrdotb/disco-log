defmodule DiscoLog do
  @moduledoc """
  Elixir-based built-in error tracking solution.
  """
  alias DiscoLog.Dedupe
  alias DiscoLog.Error
  alias DiscoLog.Storage
  alias DiscoLog.Discord.API
  alias DiscoLog.Discord.Prepare

  def report(exception, stacktrace, given_context \\ %{}, config \\ nil) do
    config = config || DiscoLog.Config.read!()
    context = Map.merge(DiscoLog.Context.get(), given_context)

    error = DiscoLog.Error.new(exception, stacktrace, context, config)
    send_error(error, config)
  end

  def send_error(%Error{} = error, config) do
    with :ok <- maybe_dedupe(error, config) do
      config.supervisor_name
      |> Storage.get_thread_id(error.fingerprint)
      |> case do
        nil ->
          available_tags = Storage.get_tags(config.supervisor_name) || %{}

          applied_tags =
            error.context
            |> Map.keys()
            |> Enum.filter(&(&1 in Map.keys(available_tags)))
            |> Enum.map(&Map.fetch!(available_tags, &1))

          message = Prepare.prepare_occurrence(error, applied_tags)

          with {:ok, %{status: 201, body: %{"id" => thread_id}}} <-
                 API.post_thread(config.discord_client, config.occurrences_channel_id, message) do
            Storage.add_thread_id(config.supervisor_name, error.fingerprint, thread_id)
          end

        thread_id ->
          message = Prepare.prepare_occurrence_message(error)

          API.post_message(config.discord_client, thread_id, message)
      end
    end
  end

  def log_info(message, metadata, config) do
    message = Prepare.prepare_message(message, metadata)

    API.post_message(config.discord_client, config.info_channel_id, message)
  end

  def log_error(message, metadata, config) do
    message = Prepare.prepare_message(message, metadata)

    API.post_message(config.discord_client, config.error_channel_id, message)
  end

  defp maybe_dedupe(%Error{} = error, config) do
    case Dedupe.insert(config.supervisor_name, error) do
      :new ->
        :ok

      :existing ->
        :excluded
    end
  end
end
