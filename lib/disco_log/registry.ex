defmodule DiscoLog.Registry do
  @moduledoc false
  def registry_name(supervisor_name), do: Module.concat(supervisor_name, Registry)

  def via(supervisor_name, server_name),
    do: {:via, Registry, {registry_name(supervisor_name), server_name}}
end
