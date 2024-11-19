defmodule Env do
  @moduledoc false
  defstruct [:method, :url, :status, :response_headers, :request_headers]
end
