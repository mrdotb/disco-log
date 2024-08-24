defmodule DiscoLog do
  @moduledoc """
  Elixir-based built-in error tracking solution.
  """

  @typedoc """
  A map containing the relevant context for a particular error.
  """
  @type context :: %{String.t() => any()}

  @type namespace :: String.t()

  @doc """
  Report an exception to be stored.

  Aside from the exception, it is expected to receive the stack trace and,
  optionally, a context map which will be merged with the current process
  context.

  Keep in mind that errors that occur in Phoenix controllers, Phoenix LiveViews
  and Oban jobs are automatically reported. You will need this function only if you
  want to report custom errors.

  ```elixir
  try do
    # your code
  catch
    e ->
      DiscoLog.report(e, __STACKTRACE__)
  end
  ```

  ## Exceptions

  Exceptions can be passed in three different forms:

  * An exception struct: the module of the exception is stored along with
  the exception message.

  * A `{kind, exception}` tuple in which case the information is converted to
  an Elixir exception (if possible) and stored.
  """
  def report(exception, stacktrace, given_context \\ %{}) do
    context = Map.merge(get_context(), given_context)

    error = DiscoLog.Error.new(exception, stacktrace, context)
    DiscoLog.Client.send_error(error)
  end

  @doc """
  Sets the current process context.

  The given context will be merged into the current process context. The given context
  may override existing keys from the current process context.

  ## Context depth

  You can store context on more than one level of depth, but take into account
  that the merge operation is performed on the first level.

  That means that any existing data on deep levels for he current context will
  be replaced if the first level key is received on the new contents.
  """
  @spec set_context(context()) :: context()
  def set_context(params) when is_map(params) do
    current_context = Process.get(:disco_log_context, %{})

    Process.put(:disco_log_context, Map.merge(current_context, params))

    params
  end

  @doc """
  Obtain the context of the current process.
  """
  @spec get_context() :: context()
  def get_context do
    Process.get(:disco_log_context, %{})
  end

  @doc """
  Set the namespace of the current process
  """
  @spec set_namespace(namespace()) :: namespace()
  def set_namespace(namespace) do
    Process.put(:disco_log_namespace, namespace)
  end

  @doc """
  Obtain the namespace of the current process.
  """
  @spec get_namespace() :: namespace()
  def get_namespace do
    Process.get(:disco_log_namespace, "backend")
  end
end
