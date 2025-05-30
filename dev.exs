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

# Configures Oban
Application.put_env(:disco_log, Demo.Repo, database: "dev.db")

defmodule Demo.Repo do
  use Ecto.Repo,
    adapter: Ecto.Adapters.SQLite3,
    otp_app: :disco_log
end

defmodule Migration0 do
  use Ecto.Migration

  def change do
    Oban.Migrations.up()
  end
end

defmodule DemoWeb.PageController do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, :index) do
    content(conn, """
    <h2>DiscoLog Dev Server</h2>

    <h3>Phoenix</h3>
    <div><a href="/plug-exception">Generate Plug exception</a></div>
    <div><a href="/noroute">Raise NoRouteError from a controller</a></div>
    <div><a href="/exception">Generate Exception</a></div>
    <div><a href="/exit">Generate Exit</a></div>

    <h3>Liveview</h3>
    <div><a href="/liveview/mount_error">Generate LiveView mount error</a></div>
    <div><a href="/liveview/multi_error/raise">Generate LiveView raise error</a></div>
    <div><a href="/liveview/multi_error/throw">Generate LiveView throw error</a></div>
    <div><a href="/liveview/component">Generate LiveView Component error</a></div>

    <h3>Logging example</h3>
    <div><a href="/new_user">Generate a new user log</a></div>
    <div><a href="/user_upgrade">Generate a pay plan log</a></div>
    <div><a href="/extra">Generate a log with attachments</a></div>
    <div><a href="/long_extra">Generate a log with long attachment</a></div>
    
    <h3>Oban example</h3>
    <div><a href="/oban/exception">Job failing with exception</a></div>
    <div><a href="/oban/throw">Job failing with a throw</a></div>
    <div><a href="/oban/exit">Job failing with exit</a></div>

    <h3>Should not generate errors</h3>
    <div><a href="/404">404 Not found</a></div>
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

defmodule DemoWeb.LogController do
  import Phoenix.Controller

  require Logger

  def init(opts), do: opts

  def call(conn, :new_user) do
    Logger.info("""
    🎉 New User Registered!
    ✨ Username: Bob
    📧 Email: bob@bob.fr
    """)

    conn
    |> redirect(to: "/")
  end

  def call(conn, :user_upgrade) do
    Logger.info("""
    🚀 Upgrade to a Paid Plan!
    ✨ Username: Bob
    💼 Plan: Pro
    """)

    conn
    |> redirect(to: "/")
  end

  def call(conn, :extra) do
    Logger.info(
      """
      ✨ Extra Log !
      📎 With attachments
      """,
      extra: %{
        username: "Bob",
        id: 1,
        and: "more",
        stuff: "here"
      }
    )

    conn
    |> redirect(to: "/")
  end

  def call(conn, :long_extra) do
    Logger.info(
      """
      ✨ Extra Long Log !
      📎 With `conn` as attachment
      """,
      extra: conn
    )

    conn
    |> redirect(to: "/")
  end
end

defmodule DemoWeb.ObanController do
  import Phoenix.Controller
  use Oban.Worker, max_attempts: 1
  
  def init(opts), do: opts
  
  def call(conn, type) do
    new(%{type: type}) |> Oban.insert!()
    
    conn
    |> redirect(to: "/")
  end
  
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => "exception"}}), do: raise "FooBar"
  def perform(%Oban.Job{args: %{"type" => "throw"}}), do: throw("catch!")
  def perform(%Oban.Job{args: %{"type" => "exit"}}), do: exit("i quit")
end

defmodule DemoWeb.MountErrorLive do
  use Phoenix.LiveView

  def mount(_params, _session, _socket) do
    :not_ok
  end

  def render(assigns) do
    ~H"""
    <h2>DiscoLog Dev Server</h2>
    """
  end
end

defmodule DemoWeb.MultiErrorLive do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(_socket, :raise, _params) do
    raise "Error raised in a live view"
  end

  defp apply_action(_socket, :throw, _params) do
    throw("Error throwed in a live view")
  end

  def render(assigns) do
    ~H"""
    <h2>DiscoLog Dev Server</h2>
    """
  end
end

defmodule DemoWeb.ErrorComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <div>error</div>
    """
  end

  def update(_assigns, socket) do
    raise "Error raised in a live component"
    {:ok, socket}
  end
end

defmodule DemoWeb.ComponentErrorLive do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.live_component id="error-component" module={DemoWeb.ErrorComponent} />
    """
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
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:fetch_session)
    plug(:protect_from_forgery)
  end

  scope "/" do
    pipe_through(:browser)
    get("/", DemoWeb.PageController, :index)
    get("/noroute", DemoWeb.PageController, :noroute)
    get("/exception", DemoWeb.PageController, :exception)
    get("/exit", DemoWeb.PageController, :exit)

    get("/new_user", DemoWeb.LogController, :new_user)
    get("/user_upgrade", DemoWeb.LogController, :user_upgrade)
    get("/extra", DemoWeb.LogController, :extra)
    get("/long_extra", DemoWeb.LogController, :long_extra)

    live("/liveview/mount_error", DemoWeb.MountErrorLive, :index)
    live("/liveview/multi_error/raise", DemoWeb.MultiErrorLive, :raise)
    live("/liveview/multi_error/throw", DemoWeb.MultiErrorLive, :throw)
    live("/liveview/component", DemoWeb.ComponentErrorLive, :update_raise)
    
    get("/oban/exception", DemoWeb.ObanController, :exception)
    get("/oban/throw", DemoWeb.ObanController, :throw)
    get("/oban/exit", DemoWeb.ObanController, :exit)
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

  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])
  socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)

  plug(Phoenix.LiveReloader)
  plug(Phoenix.CodeReloader)

  plug(Plug.Session, @session_options)

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])
  plug(:maybe_exception)
  plug(DemoWeb.Router)

  def maybe_exception(%Plug.Conn{path_info: ["plug-exception"]}, _), do: raise("Plug exception")
  def maybe_exception(conn, _), do: conn
end

Application.put_env(:phoenix, :serve_endpoints, true)

Task.async(fn ->
  children = [
    Demo.Repo,
    {Phoenix.PubSub, [name: Demo.PubSub, adapter: Phoenix.PubSub.PG2]},
    DemoWeb.Endpoint,
    {Oban, repo: Demo.Repo, engine: Oban.Engines.Lite, plugins: [], queues: [default: 10]}
  ]
  
  Demo.Repo.__adapter__().storage_down(Demo.Repo.config())
  Demo.Repo.__adapter__().storage_up(Demo.Repo.config())

  {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)
  
  Ecto.Migrator.run(Demo.Repo, [{0, Migration0}], :up, all: true)  

  Process.sleep(:infinity)
end)
