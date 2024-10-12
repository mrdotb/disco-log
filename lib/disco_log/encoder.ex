defmodule DiscoLog.Encoder do
  @moduledoc """
  Provide a safe encoding for map message which can containing any kind of
  Elixir values and need to be safely encoded to JSON.
  """
  def encode!(value, opts \\ []) do
    value
    |> encode_value()
    |> Jason.encode!(opts)
  end

  defp encode_value(value) when is_map(value) do
    value
    |> Enum.map(fn {key, value} -> {key, encode_value(value)} end)
    |> Enum.into(%{})
  end

  defp encode_value(value) when is_list(value), do: Enum.map(value, &encode_value/1)

  defp encode_value(value) when is_tuple(value),
    do: Enum.map(Tuple.to_list(value), &encode_value/1)

  defp encode_value(value) when is_pid(value), do: :erlang.pid_to_list(value)
  defp encode_value(value) when is_port(value), do: :erlang.port_to_list(value)
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  # If the binary is not a valid utf-8 string, we convert it to a utf-8 representation
  defp encode_value(value) when is_binary(value) do
    if String.valid?(value) do
      value
    else
      inspect(value, binaries: :as_binaries)
    end
  end

  # Other types are safe to be encoded as is
  defp encode_value(value), do: value
end
