defmodule DiscoLog do
  @moduledoc """
  Elixir-based built-in error tracking solution.
  """
  alias DiscoLog.Error
  alias DiscoLog.Config
  alias DiscoLog.Context
  alias DiscoLog.Storage
  alias DiscoLog.Discord.API
  alias DiscoLog.Discord.Prepare

  @spec report(Exception.kind(), any(), Exception.stacktrace(), Context.t(), Config.t() | nil) ::
          API.response()
  def report(kind, reason, stacktrace, context \\ %{}, config \\ nil) do
    config = maybe_read_config(config)
    context = Map.merge(DiscoLog.Context.get(), context)

    error = Error.new(kind, reason, stacktrace) |> Error.enrich(config)
    log_occurrence(error, context, config)
  end

  @doc false
  def log_occurrence(error, context, config) do
    config.supervisor_name
    |> Storage.get_thread_id(error.fingerprint)
    |> case do
      nil ->
        available_tags = Storage.get_tags(config.supervisor_name) || %{}

        applied_tags =
          context
          |> Map.keys()
          |> Enum.filter(&(&1 in Map.keys(available_tags)))
          |> Enum.map(&Map.fetch!(available_tags, &1))

        message =
          Prepare.prepare_occurrence(error, context, applied_tags)

        with {:ok, %{status: 201, body: %{"id" => thread_id}}} = response <-
               API.post_thread(config.discord_client, config.occurrences_channel_id, message) do
          Storage.add_thread_id(config.supervisor_name, error.fingerprint, thread_id)
          response
        end

      thread_id ->
        message = Prepare.prepare_occurrence_message(error, context)

        API.post_message(config.discord_client, thread_id, message)
    end
  end

  @spec log_info(String.t(), Context.t(), Config.t() | nil) :: API.response()
  def log_info(message, context \\ %{}, config \\ nil) do
    config = maybe_read_config(config)
    message = Prepare.prepare_message(message, context)

    API.post_message(config.discord_client, config.info_channel_id, message)
  end

  @spec log_error(String.t(), Context.t(), Config.t() | nil) :: API.response()
  def log_error(message, context \\ %{}, config \\ nil) do
    config = maybe_read_config(config)
    message = Prepare.prepare_message(message, context)

    API.post_message(config.discord_client, config.error_channel_id, message)
  end

  defp maybe_read_config(nil), do: DiscoLog.Config.read!()
  defp maybe_read_config(config), do: config
end
