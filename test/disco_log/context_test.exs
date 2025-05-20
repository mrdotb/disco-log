defmodule DiscoLog.ContextTest do
  use DiscoLog.Test.Case, async: true

  alias DiscoLog.Context

  describe inspect(&Context.set/2) do
    test "puts values under special key" do
      assert :logger.get_process_metadata() == :undefined

      Context.set(:foo, "bar")

      assert :logger.get_process_metadata() == %{
               __disco_log__: %{foo: "bar"}
             }
    end

    test "can be set multiple times" do
      Context.set(:foo, "bar")
      Context.set(:bar, "baz")

      assert :logger.get_process_metadata() == %{
               __disco_log__: %{foo: "bar", bar: "baz"}
             }
    end

    test "completely overwrites key if it exists" do
      Context.set(:foo, %{bar: "baz"})
      Context.set(:foo, %{hello: "world"})

      assert :logger.get_process_metadata() == %{
               __disco_log__: %{foo: %{hello: "world"}}
             }
    end
  end

  describe inspect(&Context.get/1) do
    test "empty map if undefined" do
      assert Context.get() == %{}
    end

    test "returns previously set values" do
      Context.set(:foo, "bar")
      Context.set(:hello, "world")

      assert Context.get() == %{foo: "bar", hello: "world"}
    end
  end
end
