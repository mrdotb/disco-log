defmodule DiscoLog.UtilsMock do
  @moduledoc false
  def application_spec(_app), do: []
end

defmodule DiscoLog.DiscordMock do
  @moduledoc false
  def list_occurrence_threads, do: []
end
