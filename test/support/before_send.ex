defmodule DiscoLog.BeforeSend do
  @moduledoc false

  def call(error) do
    pid = self()
    ref = make_ref()

    send(pid, {ref, error})
    # return false to stop the reporting
    false
  end
end
