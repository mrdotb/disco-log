defmodule DiscoLog.Integrations.Plug do
  @moduledoc """
  Integration with Plug applications.

  ## How to use it

  ### Plug applications

  The way to use this integration is by adding it to either your `Plug.Builder`
  or `Plug.Router`:

  ```elixir
  defmodule MyApp.Router do
    use Plug.Router
    
    plug DiscoLog.Integrations.Plug
    plug :match
    plug :dispatch
    
    ...
  end
  ```

  ### Phoenix applications

  Drop this plug somewhere in your `endpoint.ex`:

  ```elixir
  defmodule MyApp.Endpoint do
    ...
    
    plug DiscoLog.Integrations.Plug
    
    ...
  end
  ```

  ### Default context

  By default we store some context for you on errors generated during a Plug
  request:

  * `request.host`: the `conn.host` value.

  * `request.ip`: the IP address that initiated the request. It includes parsing
  proxy headers

  * `request.method`: the HTTP method of the request.

  * `request.path`: the path of the request.

  * `request.query`: the query string of the request.

  * `request.params`: parsed params of the request (only available if they have
  been fetched and parsed as part of the Plug pipeline).

  * `request.headers`: headers received on the request. All headers are included
  by default except for the `Cookie` ones, as they may include large and
  sensitive content like sessions.

  """
  alias DiscoLog.Context

  def init(opts), do: opts

  def call(conn, _opts) do
    set_context(conn)
    conn
  end

  @doc false
  def report_error(conn, reason, stack, config) do
    DiscoLog.report(reason, stack, %{"plug" => conn_context(conn)}, config)
  end

  @doc false
  def set_context(%Plug.Conn{} = conn) do
    context = conn_context(conn)
    Context.set("plug", context)
  end

  def conn_context(%Plug.Conn{} = conn) do
    %{
      "request.host" => conn.host,
      "request.path" => conn.request_path,
      "request.query" => conn.query_string,
      "request.method" => conn.method,
      "request.ip" => remote_ip(conn),
      "request.headers" => conn.req_headers |> Map.new() |> Map.drop(["cookie"]),
      # Depending on the error source, the request params may have not been fetched yet
      "request.params" => unless(is_struct(conn.params, Plug.Conn.Unfetched), do: conn.params)
    }
  end

  defp remote_ip(%Plug.Conn{} = conn) do
    remote_ip =
      case Plug.Conn.get_req_header(conn, "x-forwarded-for") do
        [x_forwarded_for | _] ->
          x_forwarded_for |> String.split(",", parts: 2) |> List.first()

        [] ->
          case :inet.ntoa(conn.remote_ip) do
            {:error, _} -> ""
            address -> to_string(address)
          end
      end

    String.trim(remote_ip)
  end
end
