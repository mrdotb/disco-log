defmodule DiscoLog.Config do
  @moduledoc """
  Configuration related module for DiscoLog.
  """

  @logger_config_keys ~w(info_channel_id info_format error_channel_id error_format)a

  def logger_enabled? do
    case Application.fetch_env(:disco_log, :enable_logger) do
      {:ok, value} -> value
      :error -> true
    end
  end

  def error_backend_enabled? do
    case Application.fetch_env(:disco_log, :enable_error_backend) do
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
end
