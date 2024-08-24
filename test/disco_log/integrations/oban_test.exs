defmodule DiscoLog.ObanTest do
  use DiscoLog.Test.Case, async: true

  test "attaches to Oban events automatically" do
    assert attached?([:oban, :job, :exception])
  end

  # describe "oban_job_exception/4" do
  # end

  defp attached?(event, function \\ nil) do
    event
    |> :telemetry.list_handlers()
    |> Enum.any?(fn %{id: id} ->
      case function do
        nil -> true
        f -> function == f
      end && id == DiscoLog.Integrations.Oban
    end)
  end

  # defp sample_metadata do
  #   %{
  #     worker: :"Test.Worker",
  #     args: %{foo: "bar"},
  #     id: 123,
  #     queue: :default,
  #     attempt: 1
  #   }
  # end

  # defp execute_job_exception(additional_metadata \\ %{}) do
  #   raise "Exception!"
  # catch
  #   kind, reason ->
  #     metadata =
  #       Map.merge(sample_metadata(), %{
  #         kind: kind,
  #         error: reason,
  #         stacktrace: __STACKTRACE__
  #       })

  #     :telemetry.execute(
  #       [:oban, :job, :exception],
  #       %{duration: 123 * 1_000_000},
  #       Map.merge(metadata, additional_metadata)
  #     )
  # end
end
