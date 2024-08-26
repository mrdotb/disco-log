defmodule DiscoLog.Config do
  @moduledoc """
  Configuration related module for DiscoLog.
  """

  @logger_config_keys ~w(metadata)a

  def logger_enabled? do
    case Application.fetch_env(:disco_log, :enable_logger) do
      {:ok, value} -> value
      :error -> true
    end
  end

  def instrument_oban? do
    case Application.fetch_env(:disco_log, :instrument_oban) do
      {:ok, value} -> value
      :error -> true
    end
  end

  def instrument_phoenix? do
    case Application.fetch_env(:disco_log, :instrument_phoenix) do
      {:ok, value} -> value
      :error -> true
    end
  end

  def logger_config do
    config = Application.get_all_env(:disco_log)
    Keyword.take(config, @logger_config_keys)
  end

  def before_send do
    case Application.fetch_env(:disco_log, :before_send) do
      {:ok, value} -> value
      :error -> nil
    end
  end
end
