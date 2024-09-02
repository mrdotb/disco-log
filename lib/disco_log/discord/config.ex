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

  def category, do: @category
  def occurrences_channel, do: @occurrences_channel
  def info_channel, do: @info_channel
  def error_channel, do: @error_channel
  def tags, do: @tags

  def token, do: Application.fetch_env!(:disco_log, :token)
  def guild_id, do: Application.fetch_env!(:disco_log, :guild_id)
  def category_id, do: Application.fetch_env!(:disco_log, :category_id)
  def occurrences_channel_id, do: Application.fetch_env!(:disco_log, :occurrences_channel_id)
  def info_channel_id, do: Application.fetch_env!(:disco_log, :info_channel_id)
  def error_channel_id, do: Application.fetch_env!(:disco_log, :error_channel_id)

  def enable_log? do
    case Application.fetch_env(:disco_log, :enable_discord_log) do
      {:ok, value} -> value
      :error -> false
    end
  end

  def occurrences_channel_tag_id(tag) do
    :disco_log
    |> Application.fetch_env!(:occurrences_channel_tags)
    |> Map.fetch!(tag)
  end
end
