defmodule DiscoLog.UtilsBehaviour do
  @moduledoc false
  @callback application_spec(atom) :: [{atom, term}] | nil
end

defmodule DiscoLog.UtilsImpl do
  @moduledoc false
  @behaviour DiscoLog.UtilsBehaviour

  @impl true
  def application_spec(app) do
    Application.spec(app)
  end
end

defmodule DiscoLog.Utils do
  @moduledoc false
  def application_spec(app), do: impl().application_spec(app)

  defp impl, do: Application.get_env(:disco_log, :utils, DiscoLog.UtilsImpl)
end
