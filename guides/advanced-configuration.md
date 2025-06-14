# Advanced Configuration

By default, `DiscoLog` runs a supervisor with all necessary processes under its
own application. However, you can run everything manually in case you want to log
to multiple servers, take advantage of logger filters and other features, or
simply have better control over how logging is run within your application.

> #### Mix Tasks {: .warning}
>
> Mix tasks that come with `DiscoLog` always read from the default configuration 
and won't work with advanced setup.

First, disable the `DiscoLog` default application in your `config/config.exs`:

```elixir
config :disco_log, enable: false
```

Then, define the `DiscoLog` configuration the way you want it. For example, in
the config under your application's key. Let's say you want to log to not one
but 2 Discord servers at once:

```elixir
config :my_app, DiscoLog,
  shared: [
    otp_app: :my_app,
    metadata: [:extra]
  ],
  server_a: [
    guild_id: "1234567891011121314",
    token: "server_A_secret_token",
    category_id: "1234567891011121314",
    occurrences_channel_id: "1234567891011121314",
    info_channel_id: "1234567891011121314",
    error_channel_id: "1234567891011121314",
    supervisor_name: MyApp.DiscoLog.ServerA
  ],
  server_b: [
    guild_id: "9876543210123456789",
    token: "server_B_secret_token",
    category_id: "9876543210123456789",
    occurrences_channel_id: "9876543210123456789",
    info_channel_id: "9876543210123456789",
    error_channel_id: "9876543210123456789",
    supervisor_name: MyApp.DiscoLog.ServerB
  ]
```

Finally, at startup, you'll need to start as many `DiscoLog.Supervisor` as you
need and attach the logger handlers. They share the same configuration, which
you can validate with `DiscoLog.Config.validate!/1`. Note the `supervisor_name`
configuration option. This is what tells the logger handler which supervisor
process it should use.

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    [
      shared: shared,
      server_a: config_a,
      server_b: config_b
    ] = Application.fetch_env!(:my_app, DiscoLog)

    config_a = DiscoLog.Config.validate!(shared ++ config_a)
    config_b = DiscoLog.Config.validate!(shared ++ config_b)
    
    :logger.add_handler(:disco_server_a, DiscoLog.LoggerHandler, %{config: config_a})
    :logger.add_handler(:disco_server_b, DiscoLog.LoggerHandler, %{config: config_b})

    children = [
      {DiscoLog.Supervisor, config_a},
      {DiscoLog.Supervisor, config_b},
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
```

That's it! From here, you can build upon a highly flexible Elixir logging stack
with `DiscoLog`!