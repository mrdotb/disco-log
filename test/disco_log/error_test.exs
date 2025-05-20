defmodule DiscoLog.ErrorTest do
  use DiscoLog.Test.Case, async: true

  alias DiscoLog.Error

  @repo_url "https://github.com/mrdotb/disco-log/blob"

  @config %{
    in_app_modules: [__MODULE__],
    enable_go_to_repo: true,
    repo_url: @repo_url,
    git_sha: "commit_sha",
    go_to_repo_top_modules: []
  }

  describe "enrich" do
    test "different exit reasons group together" do
      fun = fn reason -> exit(reason) end
      error1 = build_error(fun, "foo")
      error2 = build_error(fun, "bar")

      assert error1.fingerprint_basis == error2.fingerprint_basis
      assert @repo_url <> "/commit_sha/test/disco_log/error_test.exs#L18" = error1.source_url
    end

    test "different throw values reasons grouped together" do
      fun = fn value -> throw(value) end
      error1 = build_error(fun, "foo")
      error2 = build_error(fun, "bar")

      assert error1.fingerprint_basis == error2.fingerprint_basis
      assert @repo_url <> "/commit_sha/test/disco_log/error_test.exs#L27" = error1.source_url
    end

    test "same exceptions grouped together" do
      fun = fn _ -> raise "Hello" end
      error1 = build_error(fun, nil)
      error2 = build_error(fun, nil)

      assert error1.fingerprint_basis == error2.fingerprint_basis
      assert @repo_url <> "/commit_sha/test/disco_log/error_test.exs#L36" = error1.source_url
    end

    test "same exception types are grouped" do
      fun = fn arg -> if(arg == 1, do: raise("A"), else: raise("B")) end

      error1 = build_error(fun, 1)
      error2 = build_error(fun, 2)

      assert error1.fingerprint_basis == error2.fingerprint_basis
      assert @repo_url <> "/commit_sha/test/disco_log/error_test.exs#L45" = error1.source_url
    end

    test "same exceptions but arguments part of stacktrace" do
      fun = fn nil -> :ok end
      error1 = build_error(fun, :foo)
      error2 = build_error(fun, :bar)

      assert error1.fingerprint_basis == error2.fingerprint_basis
      assert @repo_url <> "/commit_sha/test/disco_log/error_test.exs#L55" = error1.source_url
    end

    test "same exceptions but different lines" do
      fun = fn
        :foo -> raise "Foo"
        :bar -> raise "Foo"
      end

      error1 = build_error(fun, :foo)
      error2 = build_error(fun, :bar)

      refute error1.fingerprint_basis == error2.fingerprint_basis
      assert @repo_url <> "/commit_sha/test/disco_log/error_test.exs#L65" = error1.source_url
      assert @repo_url <> "/commit_sha/test/disco_log/error_test.exs#L66" = error2.source_url
    end

    test "different exceptions but same app path" do
      fun = fn
        1 -> String.trim(nil)
        2 -> Enum.sum(nil)
      end

      error1 = build_error(fun, 1)
      error2 = build_error(fun, 2)

      refute error1.fingerprint_basis == error2.fingerprint_basis
      assert @repo_url <> "/commit_sha/test/disco_log/error_test.exs#L99" = error1.source_url
      assert @repo_url <> "/commit_sha/test/disco_log/error_test.exs#L99" = error2.source_url
    end

    test "no in_app entries" do
      error = build_error(fn _ -> Enum.sum(nil) end, nil, %{@config | in_app_modules: []})

      refute error.source_url
    end
  end

  defp build_error(fun, arg, config \\ @config) do
    fun.(arg)
  catch
    kind, reason ->
      Error.new(kind, reason, __STACKTRACE__)
      |> Error.enrich(config)
  end
end
