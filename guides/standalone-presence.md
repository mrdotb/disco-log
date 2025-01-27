# Presence Without Logging

You can use the Disco Log Presence feature independently of logging. This is
especially useful for apps running on a single node, in which case presence can
serve as a simple way to display application status.

To set up Presence, first make sure you have disabled the default DiscoLog logger:

```elixir
config :disco_log,
  enable: false
```

Then, start a `DiscoLog.Presence` worker under your app's supervision tree. It's
probably a good idea to only start it in the `prod` environment:

```elixir
defmodule MyApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Presence should start after workers required by the HTTP client (e.g. Finch pool)
      ...
      presence(),
      ...
      MyAppWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: MyAPp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  if Mix.env() in [:prod] do
    defp presence() do 
      token = Application.fetch_env!(:disco_log, :token)
      client = DiscoLog.Discord.API.Client.client(token)

      opts = [
        bot_token: token,
        discord_client: client,
        presence_status: "I'm online!"
      ]

      %{
        id: MyApp.Presence,
        start:
          {GenServer, :start_link,
           [DiscoLog.Presence, {opts, Process.get(:"$callers", [])}, [name: MyApp.Presence]]}
      }
    end
  else
    defp presence(), do: %{id: DiscoLog.Presence, start: {Function, :identity, [:ignore]}}
  end
end
```