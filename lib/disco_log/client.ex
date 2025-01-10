defmodule DiscoLog.Client do
  @moduledoc """
  Client for DiscoLog.
  """
  alias DiscoLog.Dedupe
  alias DiscoLog.Error
  alias DiscoLog.Storage

  def send_error(%Error{} = error, config) do
    config = put_dynamic_tags(config)

    with {:ok, %Error{} = error} <- maybe_call_before_send(error, config.before_send),
         :ok <- maybe_dedupe(error, config) do
      do_send_error(error, config)
    end
  end

  def log_info(message, metadata, config) do
    with {:ok, {message, metadata}} <-
           maybe_call_before_send({message, metadata}, config.before_send) do
      config.discord.create_message(
        config.discord_config,
        config.info_channel_id,
        message,
        metadata
      )
    end
  end

  def log_error(message, metadata, config) do
    with {:ok, {message, metadata}} <-
           maybe_call_before_send({message, metadata}, config.before_send) do
      config.discord.create_message(
        config.discord_config,
        config.error_channel_id,
        message,
        metadata
      )
    end
  end

  defp maybe_dedupe(%Error{} = error, config) do
    case Dedupe.insert(config.supervisor_name, error) do
      :new ->
        :ok

      :existing ->
        :excluded
    end
  end

  defp do_send_error(%Error{} = error, config) do
    config.supervisor_name
    |> Storage.get_thread_id(error.fingerprint)
    |> create_thread_or_add_message(error, config)
  end

  defp create_thread_or_add_message(nil, error, config) do
    with {:ok, thread} <- config.discord.create_occurrence_thread(config.discord_config, error) do
      Storage.add_thread_id(config.supervisor_name, error.fingerprint, thread["id"])
    end
  end

  defp create_thread_or_add_message(thread_id, error, config) do
    config.discord.create_occurrence_message(config.discord_config, thread_id, error)
  end

  defp maybe_call_before_send(%Error{} = error, nil) do
    {:ok, error}
  end

  defp maybe_call_before_send({message, metadata}, nil) do
    {:ok, {message, metadata}}
  end

  defp maybe_call_before_send(error, callback) do
    if result = call_before_send(error, callback) do
      {:ok, result}
    else
      :excluded
    end
  end

  defp call_before_send(error, function) when is_function(function, 1) do
    function.(error) || false
  end

  defp call_before_send(error, {mod, fun}) do
    apply(mod, fun, [error]) || false
  end

  defp call_before_send(_error, other) do
    raise ArgumentError, """
    :before_send must be an anonymous function or a {module, function} tuple, got: \
    #{inspect(other)}\
    """
  end

  defp put_dynamic_tags(config) do
    update_in(config, [:discord_config, Access.key!(:occurrences_channel_tags)], fn _ ->
      Storage.get_tags(config.supervisor_name)
    end)
  end
end
