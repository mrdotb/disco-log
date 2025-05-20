defmodule DiscoLog.Discord.PrepareTest do
  use DiscoLog.Test.Case, async: true

  alias DiscoLog.Discord.Prepare
  alias DiscoLog.Error

  @error %Error{
    kind: :error,
    reason: %RuntimeError{message: "Foo"},
    display_kind: "RuntimeError",
    display_title: "RuntimeError",
    display_short_error: "Foo",
    display_full_error: """
    ** (RuntimeError) Foo
        dev.exs:111: DemoWeb.PageController.call/2
        (phoenix 1.7.21) lib/phoenix/router.ex:484: Phoenix.Router.__call__/5
        dev.exs:316: DemoWeb.Endpoint.plug_builder_call/2
        deps/plug/lib/plug/debugger.ex:155: DemoWeb.Endpoint."call (overridable 3)"/2
        dev.exs:316: DemoWeb.Endpoint."call (overridable 4)"/2
        (bandit 1.7.0) lib/bandit/pipeline.ex:131: Bandit.Pipeline.call_plug!/2
        (bandit 1.7.0) lib/bandit/pipeline.ex:42: Bandit.Pipeline.run/5
        (bandit 1.7.0) lib/bandit/http1/handler.ex:13: Bandit.HTTP1.Handler.handle_data/3
    """,
    display_source: "dev.exs:111: DemoWeb.PageController.call/2",
    fingerprint: "2sxhIQ",
    source_url: "https://github.com/mrdotb/disco-log/blob/main/dev.exs#L111"
  }

  describe inspect(&Prepare.prepare_message/2) do
    test "string message goes to content" do
      assert [payload_json: %{flags: 32_768, components: [%{type: 10, content: "Hello World"}]}] =
               Prepare.prepare_message("Hello World", %{})
    end

    test "context is attached as code block" do
      assert [
               payload_json: %{
                 flags: 32_768,
                 components: [
                   %{type: 10, content: "Hello"},
                   %{type: 10, content: "```elixir\n%{foo: \"bar\"}\n```"}
                 ]
               }
             ] = Prepare.prepare_message("Hello", %{foo: "bar"})
    end

    test "context is attached as file if it exceeds limit" do
      assert [
               payload_json: %{
                 flags: 32_768,
                 components: [
                   %{type: 10, content: "Hello"},
                   %{type: 13, file: %{url: "attachment://context.txt"}}
                 ]
               },
               context: {"%{\n  foo: " <> _, [filename: "context.txt"]}
             ] = Prepare.prepare_message("Hello", %{foo: String.duplicate("a", 4000)})
    end
  end

  describe inspect(&Prepare.prepare_occurrence/2) do
    test "applies tags from context" do
      assert [
               payload_json: %{
                 applied_tags: ["tag_id_1"]
               }
             ] =
               Prepare.prepare_occurrence(@error, %{}, ["tag_id_1"])
    end

    test "thread name is fingerprint + display_title" do
      error = %{@error | fingerprint: "AAAAAA", display_title: "Hello"}

      assert [
               payload_json: %{
                 name: "AAAAAA Hello"
               }
             ] =
               Prepare.prepare_occurrence(error, %{}, [])
    end

    test "main body" do
      error = %{
        @error
        | display_kind: "KIND",
          display_short_error: "SHORT",
          display_full_error: "FULL",
          display_source: "SOURCE",
          source_url: "http://example.com"
      }

      assert [
               payload_json: %{
                 message: %{
                   flags: 32_768,
                   components: [
                     %{
                       type: 10,
                       content: """
                       **Kind:** `KIND`
                       **Reason:** `SHORT`
                       **Source:** [SOURCE](http://example.com)
                       ```\nFULL\n```\
                       """
                     }
                   ]
                 }
               }
             ] =
               Prepare.prepare_occurrence(error, %{}, [])
    end

    test "display_kind and display_source are optional" do
      error = %{
        @error
        | display_kind: nil,
          display_short_error: "SHORT",
          display_full_error: "FULL",
          display_source: nil,
          source_url: "http://example.com"
      }

      assert [
               payload_json: %{
                 message: %{
                   flags: 32_768,
                   components: [
                     %{
                       type: 10,
                       content: """
                       **Reason:** `SHORT`
                       ```\nFULL\n```\
                       """
                     }
                   ]
                 }
               }
             ] =
               Prepare.prepare_occurrence(error, %{}, [])
    end

    test "context is attached as code block" do
      assert [
               payload_json: %{
                 message: %{
                   flags: 32_768,
                   components: [
                     _,
                     %{type: 10, content: "```elixir\n%{foo: \"bar\"}\n```"}
                   ]
                 }
               }
             ] = Prepare.prepare_occurrence(@error, %{foo: "bar"}, [])
    end

    test "context is attached as file if it exceeds limit" do
      assert [
               payload_json: %{
                 message: %{
                   flags: 32_768,
                   components: [_, %{type: 13, file: %{url: "attachment://context.txt"}}]
                 }
               },
               context: {"%{\n  foo: " <> _, [filename: "context.txt"]}
             ] = Prepare.prepare_occurrence(@error, %{foo: String.duplicate("a", 4000)}, [])
    end
  end

  describe inspect(&Prepare.prepare_occurrence_message/1) do
    test "creates new message to be put in thread" do
      error = %{
        @error
        | display_kind: "KIND",
          display_short_error: "SHORT",
          display_full_error: "FULL",
          display_source: "SOURCE",
          source_url: "http://example.com"
      }

      assert [
               payload_json: %{
                 components: [
                   %{
                     type: 10,
                     content: """
                     **Kind:** `KIND`
                     **Reason:** `SHORT`
                     **Source:** [SOURCE](http://example.com)
                     ```\nFULL\n```\
                     """
                   }
                 ],
                 flags: 32_768
               }
             ] =
               Prepare.prepare_occurrence_message(error, %{})
    end

    test "display_kind and display_source are optional" do
      error = %{
        @error
        | display_kind: nil,
          display_short_error: "SHORT",
          display_full_error: "FULL",
          display_source: nil,
          source_url: "http://example.com"
      }

      assert [
               payload_json: %{
                 components: [
                   %{
                     type: 10,
                     content: """
                     **Reason:** `SHORT`
                     ```\nFULL\n```\
                     """
                   }
                 ],
                 flags: 32_768
               }
             ] =
               Prepare.prepare_occurrence_message(error, %{})
    end

    test "context is attached as code block" do
      assert [
               payload_json: %{
                 components: [_, %{type: 10, content: "```elixir\n%{foo: \"bar\"}\n```"}],
                 flags: 32_768
               }
             ] =
               Prepare.prepare_occurrence_message(@error, %{foo: "bar"})
    end

    test "context is attached as file if it exceeds limit" do
      assert [
               payload_json: %{
                 components: [_, %{type: 13, file: %{url: "attachment://context.txt"}}],
                 flags: 32_768
               },
               context: {"%{\n  foo: " <> _, [filename: "context.txt"]}
             ] =
               Prepare.prepare_occurrence_message(@error, %{
                 foo: String.duplicate("a", 4000)
               })
    end
  end
end
