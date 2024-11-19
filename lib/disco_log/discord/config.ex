defmodule DiscoLog.Discord.Config do
  @moduledoc """
  Discord configuration module.
  """

  @category %{
    name: "disco-log",
    type: 4
  }

  @tags ~w(plug live_view oban)s

  @occurrences_channel %{
    name: "occurrences",
    type: 15,
    available_tags: Enum.map(@tags, &%{name: &1})
  }

  @info_channel %{
    name: "info",
    type: 0
  }

  @error_channel %{
    name: "error",
    type: 0
  }

  defstruct category: @category,
            tags: @tags,
            occurrences_channel: @occurrences_channel,
            info_channel: @info_channel,
            error_channel: @error_channel,
            token: nil,
            guild_id: nil,
            category_id: nil,
            occurrences_channel_id: nil,
            occurrences_channel_tags: %{},
            info_channel_id: nil,
            error_channel_id: nil,
            enable_discord_log: nil

  @spec new(DiscoLog.Config.config()) :: %__MODULE__{}
  def new(config) do
    struct(__MODULE__, config)
  end
end
