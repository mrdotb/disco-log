defmodule DiscoLog.Discord.PrepareTest do
  use DiscoLog.Test.Case, async: true

  alias DiscoLog.Discord.Prepare

  describe inspect(&Prepare.prepare_message/2) do
    test "string message goes to content" do
      assert [payload_json: "{\"content\":\"Hello World\"}"] =
               Prepare.prepare_message("Hello World", %{})
    end

    test "map message is attached as a json file" do
      assert [message: {"{\n  \"foo\": \"bar\"\n}", [filename: "message.json"]}] =
               Prepare.prepare_message(%{foo: "bar"}, %{})
    end

    test "metadata is attached" do
      assert [
               metadata: {"%{foo: \"bar\"}", [filename: "metadata.ex"]},
               payload_json: "{\"content\":\"Hello\"}"
             ] = Prepare.prepare_message("Hello", %{foo: "bar"})
    end
  end

  describe inspect(&Prepare.prepare_occurrence/2) do
    test "creates new thread with tags" do
      error = %DiscoLog.Error{
        kind: "Elixir.RuntimeError",
        reason: "foo",
        source_line: "iex:7",
        source_function: "elixir_eval.__FILE__/1",
        context: %{},
        stacktrace: %DiscoLog.Stacktrace{
          lines: [
            %DiscoLog.Stacktrace.Line{
              application: "",
              module: "elixir_eval",
              top_module: "elixir_eval",
              function: "__FILE__",
              arity: 1,
              file: "iex",
              line: 7
            },
            %DiscoLog.Stacktrace.Line{
              application: "elixir",
              module: "elixir",
              top_module: "elixir",
              function: "eval_external_handler",
              arity: 3,
              file: "src/elixir.erl",
              line: 386
            },
            %DiscoLog.Stacktrace.Line{
              application: "stdlib",
              module: "erl_eval",
              top_module: "erl_eval",
              function: "do_apply",
              arity: 7,
              file: "erl_eval.erl",
              line: 919
            },
            %DiscoLog.Stacktrace.Line{
              application: "stdlib",
              module: "erl_eval",
              top_module: "erl_eval",
              function: "try_clauses",
              arity: 10,
              file: "erl_eval.erl",
              line: 1233
            },
            %DiscoLog.Stacktrace.Line{
              application: "elixir",
              module: "elixir",
              top_module: "elixir",
              function: "eval_forms",
              arity: 4,
              file: "src/elixir.erl",
              line: 364
            },
            %DiscoLog.Stacktrace.Line{
              application: "elixir",
              module: "Module.ParallelChecker",
              top_module: "Module",
              function: "verify",
              arity: 1,
              file: "lib/module/parallel_checker.ex",
              line: 120
            },
            %DiscoLog.Stacktrace.Line{
              application: "iex",
              module: "IEx.Evaluator",
              top_module: "IEx",
              function: "eval_and_inspect",
              arity: 3,
              file: "lib/iex/evaluator.ex",
              line: 336
            },
            %DiscoLog.Stacktrace.Line{
              application: "iex",
              module: "IEx.Evaluator",
              top_module: "IEx",
              function: "eval_and_inspect_parsed",
              arity: 3,
              file: "lib/iex/evaluator.ex",
              line: 310
            }
          ]
        },
        fingerprint: "DDF3A140618A73A3",
        source_url: nil
      }

      assert [
               stacktrace: {"elixir_eval.__FILE__/1 in" <> _, [filename: "stacktrace.ex"]},
               payload_json: payload
             ] = Prepare.prepare_occurrence(error, ["tag_id_1"])

      assert %{
               "applied_tags" => ["tag_id_1"],
               "message" => %{
                 "content" => "  **At:** " <> _
               },
               "name" => <<_::binary-size(16)>> <> " Elixir.RuntimeError"
             } = Jason.decode!(payload)
    end
  end

  describe inspect(&Prepare.prepare_occurence_message/1) do
    test "creates new message to be put in thread" do
      error = %DiscoLog.Error{
        kind: "Elixir.RuntimeError",
        reason: "foo",
        source_line: "iex:7",
        source_function: "elixir_eval.__FILE__/1",
        context: %{},
        stacktrace: %DiscoLog.Stacktrace{
          lines: [
            %DiscoLog.Stacktrace.Line{
              application: "",
              module: "elixir_eval",
              top_module: "elixir_eval",
              function: "__FILE__",
              arity: 1,
              file: "iex",
              line: 7
            },
            %DiscoLog.Stacktrace.Line{
              application: "elixir",
              module: "elixir",
              top_module: "elixir",
              function: "eval_external_handler",
              arity: 3,
              file: "src/elixir.erl",
              line: 386
            },
            %DiscoLog.Stacktrace.Line{
              application: "stdlib",
              module: "erl_eval",
              top_module: "erl_eval",
              function: "do_apply",
              arity: 7,
              file: "erl_eval.erl",
              line: 919
            },
            %DiscoLog.Stacktrace.Line{
              application: "stdlib",
              module: "erl_eval",
              top_module: "erl_eval",
              function: "try_clauses",
              arity: 10,
              file: "erl_eval.erl",
              line: 1233
            },
            %DiscoLog.Stacktrace.Line{
              application: "elixir",
              module: "elixir",
              top_module: "elixir",
              function: "eval_forms",
              arity: 4,
              file: "src/elixir.erl",
              line: 364
            },
            %DiscoLog.Stacktrace.Line{
              application: "elixir",
              module: "Module.ParallelChecker",
              top_module: "Module",
              function: "verify",
              arity: 1,
              file: "lib/module/parallel_checker.ex",
              line: 120
            },
            %DiscoLog.Stacktrace.Line{
              application: "iex",
              module: "IEx.Evaluator",
              top_module: "IEx",
              function: "eval_and_inspect",
              arity: 3,
              file: "lib/iex/evaluator.ex",
              line: 336
            },
            %DiscoLog.Stacktrace.Line{
              application: "iex",
              module: "IEx.Evaluator",
              top_module: "IEx",
              function: "eval_and_inspect_parsed",
              arity: 3,
              file: "lib/iex/evaluator.ex",
              line: 310
            }
          ]
        },
        fingerprint: "DDF3A140618A73A3",
        source_url: nil
      }

      assert [
               stacktrace: {"elixir_eval.__FILE__/1 in" <> _, [filename: "stacktrace.ex"]},
               payload_json: payload
             ] = Prepare.prepare_occurrence_message(error)

      assert %{
               "content" => "  **At:** " <> _
             } = Jason.decode!(payload)
    end
  end
end
