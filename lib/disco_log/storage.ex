defmodule DiscoLog.Storage do
  @moduledoc """
  A GenServer to store the mapping of fingerprint to Discord Thread ID.
  """
  use GenServer

  defstruct [:registry, :discord_config, :discord]

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
  def add_thread_id(name, fingerprint, thread_id) do
    GenServer.call(
      DiscoLog.Registry.via(name, __MODULE__),
      {:add_thread_id, fingerprint, thread_id}
    )
  end

  @doc "Retrieve the thread_id for a given fingerprint"
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
      discord_config: Keyword.fetch!(opts, :discord_config),
      discord: Keyword.fetch!(opts, :discord)
    }

    Process.put(:"$callers", callers)

    {:ok, state, {:continue, :restore}}
  end

  @impl GenServer
  def handle_continue(
        :restore,
        %__MODULE__{discord_config: config, discord: discord, registry: registry} = state
      ) do
    existing_threads =
      config
      |> discord.list_occurrence_threads(config.occurrences_channel_id)
      |> Map.new()

    existing_tags = discord.list_tags(config, config.occurrences_channel_id)

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
