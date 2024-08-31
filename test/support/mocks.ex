defmodule DiscoLog.DiscordMock do
  @moduledoc false
  def list_occurrence_threads, do: []
end

defmodule Env do
  @moduledoc false
  defstruct [:method, :url, :status, :response_headers, :request_headers]
end
