defmodule DiscoLog.ErrorTest do
  use DiscoLog.Test.Case, async: true

  alias DiscoLog.Error

  @relative_file_path Path.relative_to(__ENV__.file, File.cwd!())

  describe inspect(&Error.new/4) do
    test "exceptions" do
      error = %Error{} = build_error(fn -> raise "This is a test" end)

      assert error.kind == to_string(RuntimeError)
      assert error.reason == "This is a test"
      assert error.source_line =~ @relative_file_path

      assert error.source_function ==
               "DiscoLog.ErrorTest.-test &DiscoLog.Error.new/4 exceptions/1-fun-0-/0"

      assert error.context == %{}
    end

    test "badarith errors" do
      string_var = to_string(1)

      error =
        %Error{} =
        build_error(fn -> 1 + string_var end)

      assert error.kind == to_string(ArithmeticError)
      assert error.reason == "bad argument in arithmetic expression"

      # Elixir 1.17.0 reports this errors differntly than previous versions
      if Version.compare(System.version(), "1.17.0") == :lt do
        assert error.source_line =~ @relative_file_path
      else
        assert error.source_function == "erlang.+/2"
        assert error.source_line == "nofile"
      end
    end

    test "undefined function errors" do
      # This function does not exist and will raise when called
      {m, f, a} = {DiscoLog, :invalid_fun, []}

      %Error{} =
        error =
        build_error(fn -> apply(m, f, a) end)

      assert error.kind == to_string(UndefinedFunctionError)
      assert error.reason =~ "is undefined or private"
      assert error.source_function == Exception.format_mfa(m, f, Enum.count(a))
      assert error.source_line == "nofile"
    end

    test "throws" do
      %Error{} =
        error =
        build_error(fn -> throw("This is a test") end)

      assert error.kind == "throw"
      assert error.reason == "This is a test"
      assert error.source_line =~ @relative_file_path
    end

    test "exits" do
      %Error{} =
        error =
        build_error(fn -> exit("This is a test") end)

      assert error.kind == "exit"
      assert error.reason == "This is a test"
      assert error.source_line =~ @relative_file_path
    end

    test "similar error should have the same fingerprint " do
      error1 = unique_error()
      error2 = unique_error()

      assert error1.fingerprint == error2.fingerprint
    end
  end

  describe inspect(&Error.hash/1) do
    test "similar error should have different hash" do
      error1 = unique_error()
      error2 = unique_error()

      assert Error.hash(error1) != Error.hash(error2)
    end
  end

  defp unique_error do
    build_error(fn -> raise "I am unique" end)
  end
end
