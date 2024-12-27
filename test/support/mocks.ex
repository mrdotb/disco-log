Mox.defmock(DiscoLog.DiscordMock, for: DiscoLog.DiscordBehaviour)
Mox.defmock(DiscoLog.WebsocketClient.Mock, for: DiscoLog.WebsocketClient)

defmodule Env do
  @moduledoc false
  defstruct [:method, :url, :status, :response_headers, :request_headers]
end
