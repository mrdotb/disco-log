defmodule DiscoLog do
  @moduledoc """
  Send messages to Discord

  All functions in this module accept optional `context` and `config` parameters.
  * `context` is the last opportunity to assign some metadata that will be
  attached to the message or occurrence. Occurrences will additionally be tagged
  if context key names match existing channel tags.
  * `config` is important if you're running [advanced configuration](advanced-configuration.md)
  """
  alias DiscoLog.Error
  alias DiscoLog.Config
  alias DiscoLog.Context
  alias DiscoLog.Storage
  alias DiscoLog.Discord.API
  alias DiscoLog.Discord.Prepare

  @doc """
  Report catched error to occurrences channel

  This function reports an error directly to the occurrences channel, bypassing logging. 

  Example:

      try do
        raise "Unexpected!"
      catch 
        kind, reason -> DiscoLog.report(kind, reason, __STACKTRACE__)
      end
  """
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
          |> Enum.map(&to_string/1)
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

  @doc """
  Sends text message to the channel configured as `info_channel_id`
  """
  @spec log_info(String.t(), Context.t(), Config.t() | nil) :: API.response()
  def log_info(message, context \\ %{}, config \\ nil) do
    config = maybe_read_config(config)
    message = Prepare.prepare_message(message, context)

    API.post_message(config.discord_client, config.info_channel_id, message)
  end

  @doc """
  Sends text message to the channel configures as `error_channel_id`
  """
  @spec log_error(String.t(), Context.t(), Config.t() | nil) :: API.response()
  def log_error(message, context \\ %{}, config \\ nil) do
    config = maybe_read_config(config)
    message = Prepare.prepare_message(message, context)

    API.post_message(config.discord_client, config.error_channel_id, message)
  end

  defp maybe_read_config(nil), do: DiscoLog.Config.read!()
  defp maybe_read_config(config), do: config
end
