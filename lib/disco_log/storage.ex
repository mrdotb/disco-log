defmodule DiscoLog.Storage do
  @moduledoc """
  A GenServer to store the mapping of fingerprint to Discord Thread ID.
  """
  use GenServer

  alias DiscoLog.Discord

  defstruct [:registry, :discord_client, :guild_id, :occurrences_channel_id]

  ## Public API

  @doc "Start the Storage"
  def start_link(opts) do
    name =
      opts
      |> Keyword.fetch!(:supervisor_name)
      |> DiscoLog.Registry.via(__MODULE__)

    callers = Process.get(:"$callers", [])

    GenServer.start_link(__MODULE__, {opts, callers}, name: name)
  end

  @doc "Add a new fingerprint -> thread_id mapping"
  @spec add_thread_id(DiscoLog.Config.supervisor_name(), fingerprint :: String.t(), String.t()) ::
          :ok
  def add_thread_id(name, fingerprint, thread_id) do
    GenServer.call(
      DiscoLog.Registry.via(name, __MODULE__),
      {:add_thread_id, fingerprint, thread_id}
    )
  end

  @doc "Retrieve the thread_id for a given fingerprint"
  @spec get_thread_id(DiscoLog.Config.supervisor_name(), fingerprint :: String.t()) ::
          String.t() | nil
  def get_thread_id(name, fingerprint) do
    name
    |> DiscoLog.Registry.registry_name()
    |> Registry.lookup({__MODULE__, :threads})
    |> case do
      [{_, %{^fingerprint => thread_id}}] -> thread_id
      _ -> nil
    end
  end

  @doc "Retrieve the tag id for a given tag"
  @spec get_tags(DiscoLog.Config.supervisor_name()) :: String.t() | nil
  def get_tags(name) do
    name
    |> DiscoLog.Registry.registry_name()
    |> Registry.lookup({__MODULE__, :tags})
    |> case do
      [{_, tags}] -> tags
      _ -> nil
    end
  end

  ## Callbacks

  @impl GenServer
  def init({opts, callers}) do
    state = %__MODULE__{
      registry: DiscoLog.Registry.registry_name(opts[:supervisor_name]),
      discord_client: Keyword.fetch!(opts, :discord_client),
      guild_id: Keyword.fetch!(opts, :guild_id),
      occurrences_channel_id: Keyword.fetch!(opts, :occurrences_channel_id)
    }

    Process.put(:"$callers", callers)

    {:ok, state, {:continue, :restore}}
  end

  @impl GenServer
  def handle_continue(
        :restore,
        %__MODULE__{
          discord_client: discord_client,
          guild_id: guild_id,
          occurrences_channel_id: occurrences_channel_id,
          registry: registry
        } =
          state
      ) do
    {:ok, existing_threads} =
      Discord.list_occurrence_threads(discord_client, guild_id, occurrences_channel_id)

    {:ok, existing_tags} = Discord.list_occurrence_tags(discord_client, occurrences_channel_id)

    Registry.register(registry, {__MODULE__, :threads}, existing_threads)
    Registry.register(registry, {__MODULE__, :tags}, existing_tags)

    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:add_thread_id, fingerprint, thread_id}, _from, state) do
    Registry.update_value(state.registry, {__MODULE__, :threads}, fn threads ->
      Map.put(threads, fingerprint, thread_id)
    end)

    {:reply, :ok, state}
  end
end
