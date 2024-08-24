defmodule DiscoLog.Storage do
  @moduledoc """
  A GenServer to store the mapping of fingerprint to Discord Thread ID using ETS.
  """
  use GenServer

  alias DiscoLog.Discord

  @ets __MODULE__

  ## Public API

  @doc "Start the Storage"
  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @doc "Add a new fingerprint -> thread_id mapping"
  def add_thread_id(fingerprint, thread_id),
    do: GenServer.call(__MODULE__, {:add_thread_id, fingerprint, thread_id})

  @doc "Retrieve the thread_id for a given fingerprint"
  def get_thread_id(fingerprint), do: GenServer.call(__MODULE__, {:get_thread_id, fingerprint})

  ## Callbacks

  @impl GenServer
  def init(_args) do
    :ets.new(@ets, [:named_table, :public, :set])
    {:ok, [], {:continue, :restore}}
  end

  @impl GenServer
  def handle_continue(:restore, state) do
    Discord.list_occurence_threads()
    |> Enum.each(fn {fingerprint, thread_id} ->
      :ets.insert(@ets, {fingerprint, thread_id})
    end)

    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:add_thread_id, fingerprint, thread_id}, _from, state) do
    :ets.insert(@ets, {fingerprint, thread_id})
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call({:get_thread_id, fingerprint}, _from, state) do
    thread_id =
      case :ets.lookup(@ets, fingerprint) do
        [{^fingerprint, thread_id}] -> thread_id
        [] -> nil
      end

    {:reply, thread_id, state}
  end
end
