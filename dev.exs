#######################################
# Development Server for DiscoLog.
#
# Based on PhoenixLiveDashboard code.
#
# Usage:
#
# $ iex -S mix dev
#######################################
Logger.configure(level: :debug)

# Get configuration
Config.Reader.read!("config/config.exs", env: :dev)

# Configures the endpoint
Application.put_env(:disco_log, DemoWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Hu4qQN3iKzTV4fJxhorPQlA/osH9fAMtbtjVS58PFgfw3ja5Z18Q/WSNR9wP4OfW",
  live_view: [signing_salt: "hMegieSe"],
  http: [port: System.get_env("PORT") || 4000],
  debug_errors: true,
  check_origin: false,
  pubsub_server: Demo.PubSub,
  live_reload: [
    patterns: [
      ~r"dev.exs$",
      ~r"dist/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/error_tracker/web/(live|views)/.*(ex)$",
      ~r"lib/error_tracker/web/templates/.*(ex)$"
    ]
  ]
)

defmodule DemoWeb.PageController do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, :index) do
    content(conn, """
    <h2>DiscoLog Dev Server</h2>
    <div><a href="/plug-exception">Generate Plug exception</a></div>
    <div><a href="/404">Generate Router 404</a></div>
    <div><a href="/noroute">Raise NoRouteError from a controller</a></div>
    <div><a href="/exception">Generate Exception</a></div>
    <div><a href="/exit">Generate Exit</a></div>
    """)
  end

  def call(conn, :noroute) do
    raise Phoenix.Router.NoRouteError, conn: conn, router: DiscoLogDevWeb.Router
  end

  def call(_conn, :exception) do
    raise "This is a controller exception"
  end

  def call(_conn, :exit) do
    exit(:timeout)
  end

  defp content(conn, content) do
    conn
    |> put_resp_header("content-type", "text/html")
    |> send_resp(200, "<!doctype html><html><body>#{content}</body></html>")
  end
end

defmodule DiscoLogDevWeb.ErrorView do
  def render("404.html", _assigns) do
    "This is a 404"
  end

  def render("500.html", _assigns) do
    "This is a 500"
  end
end

defmodule DemoWeb.Router do
  use Phoenix.Router

  pipeline :browser do
    plug :fetch_session
    plug :protect_from_forgery
  end

  scope "/" do
    pipe_through :browser
    get "/", DemoWeb.PageController, :index
    get "/noroute", DemoWeb.PageController, :noroute
    get "/exception", DemoWeb.PageController, :exception
    get "/exit", DemoWeb.PageController, :exit
  end
end

defmodule DemoWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :disco_log
  use DiscoLog.Integrations.Plug

  @session_options [
    store: :cookie,
    key: "_disco_log_dev",
    signing_salt: "/VEDsdfsffMnp5",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]
  socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket

  plug Phoenix.LiveReloader
  plug Phoenix.CodeReloader

  plug Plug.Session, @session_options

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
  plug :maybe_exception
  plug DemoWeb.Router

  def maybe_exception(%Plug.Conn{path_info: ["plug-exception"]}, _), do: raise("Plug exception")
  def maybe_exception(conn, _), do: conn
end

Application.put_env(:phoenix, :serve_endpoints, true)

Task.async(fn ->
  children = [
    {Phoenix.PubSub, [name: Demo.PubSub, adapter: Phoenix.PubSub.PG2]},
    DemoWeb.Endpoint
  ]

  {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)
  Process.sleep(:infinity)
end)
