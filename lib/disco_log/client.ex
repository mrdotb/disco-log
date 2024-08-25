defmodule DiscoLog.Client do
  @moduledoc """
  Client for DiscoLog.
  """

  alias DiscoLog.Config
  alias DiscoLog.Dedupe
  alias DiscoLog.Discord
  alias DiscoLog.Error
  alias DiscoLog.Storage

  def send_error(%Error{} = error) do
    with {:ok, %Error{} = error} <- maybe_call_before_send(error, Config.before_send()),
         :ok <- maybe_dedupe(error) do
      send(error)
    end
  end

  defp maybe_dedupe(%Error{} = error) do
    case Dedupe.insert(error) do
      :new ->
        :ok

      :existing ->
        :excluded
    end
  end

  defp send(%Error{} = error) do
    error.fingerprint
    |> Storage.get_thread_id()
    |> create_thread_or_add_message(error)
  end

  defp create_thread_or_add_message(nil, error) do
    with {:ok, thread} <- Discord.create_occurrence_thread(error) do
      Storage.add_thread_id(error.fingerprint, thread["id"])
    end
  end

  defp create_thread_or_add_message(thread_id, error) do
    Discord.create_occurrence_message(thread_id, error)
  end

  def log_info(message, metadata) do
    Discord.create_message(Discord.Config.info_channel_id(), message, metadata)
  end

  def log_error(message, metadata) do
    Discord.create_message(Discord.Config.error_channel_id(), message, metadata)
  end

  defp maybe_call_before_send(%Error{} = error, nil) do
    {:ok, error}
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
end
