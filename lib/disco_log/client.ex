defmodule DiscoLog.Client do
  @moduledoc """
  Client for DiscoLog.
  """

  alias DiscoLog.Dedupe
  alias DiscoLog.Discord
  alias DiscoLog.Error
  alias DiscoLog.Storage

  def send_error(%Error{} = error) do
    with :ok <- maybe_dedupe(error) do
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
end
