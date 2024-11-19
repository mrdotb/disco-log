defmodule DiscoLog.ApplicationTest do
  # We test through global handler here which other test may interfere with
  use DiscoLog.Test.Case, async: false

  import Mox

  setup_all :set_mox_global

  setup_all do
    Mox.stub(DiscoLog.DiscordMock, :list_occurrence_threads, fn _, _ -> [] end)

    Application.put_env(:disco_log, :enable, true)
    Application.stop(:disco_log)
    Application.start(:disco_log)

    on_exit(fn ->
      :logger.remove_handler(DiscoLog.Application)
      Application.put_env(:disco_log, :enable, false)
      Application.stop(:disco_log)
      Application.start(:disco_log)
    end)
  end

  test "starts default supervisor under application name" do
    assert [{_id, pid, :supervisor, [DiscoLog.Supervisor]}] =
             Supervisor.which_children(Process.whereis(DiscoLog.Application))

    assert [
             {DiscoLog.Dedupe, dedupe_pid, :worker, _},
             {DiscoLog.Storage, storage_pid, :worker, _},
             {DiscoLog.Registry, registry_pid, :supervisor, _}
           ] = Supervisor.which_children(pid)

    for pid <- [dedupe_pid, storage_pid, registry_pid] do
      assert :sys.get_status(pid)
    end
  end

  test "attaches logger handler" do
    assert {:ok, %{module: DiscoLog.LoggerHandler}} =
             :logger.get_handler_config(DiscoLog.Application)
  end
end
