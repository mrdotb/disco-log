# Getting Started

This guide is an introduction to DiscoLog. It will guide you through the setup of DiscoLog and how to use it.

## Install DiscoLog

The first step is to add DiscoLog to your applicaiton is to declare the package as a dependency in your `mix.exs` file.

```elixir
defp deps do
  [
    {:disco_log, "~> 0.1.0"}
  ]
end
```

Then run the following command to fetch the dependencies.

```bash
mix deps.get
```

## Setup the Discord Server

You need to register a [Discord Account](https://discord.com/)

### Create a community Discord Server
*A Discord community server needs to have a forum-type channel, which we use for error tracking.*

<img src="https://raw.githubusercontent.com/mrdotb/i/master/disco-log/1-create-server.png" alt="Create Server step 1" />
<img src="https://raw.githubusercontent.com/mrdotb/i/master/disco-log/2-create-server.png" alt="Create Server step 2" />
<img src="https://raw.githubusercontent.com/mrdotb/i/master/disco-log/3-create-server.png" alt="Create Server step 3" />

### Edit the Discord Server settings

*Right-click on the server and select `Server Settings` > `Community Settings`*
<img src="https://raw.githubusercontent.com/mrdotb/i/master/disco-log/4-edit-server.png" alt="Edit Server step 4" />
<img src="https://raw.githubusercontent.com/mrdotb/i/master/disco-log/5-edit-server.png" alt="Edit Server step 5" />
<img src="https://raw.githubusercontent.com/mrdotb/i/master/disco-log/6-edit-server.png" alt="Edit Server step 6" />
<img src="https://raw.githubusercontent.com/mrdotb/i/master/disco-log/7-edit-server.png" alt="Edit Server step 7" />
<img src="https://raw.githubusercontent.com/mrdotb/i/master/disco-log/8-edit-server.png" alt="Edit Server step 8" />

*Copy the server ID, it will be needed later*

<img src="https://raw.githubusercontent.com/mrdotb/i/master/disco-log/9-copy-server-id.png" alt="Edit Server step 9" />

## Create a Discord Bot

Go to the [developers portal](https://discord.com/developers/applications)

<img src="https://raw.githubusercontent.com/mrdotb/i/master/disco-log/10-create-bot.png" alt="Create bot 1" />
<img src="https://raw.githubusercontent.com/mrdotb/i/master/disco-log/11-create-bot.png" alt="Create bot 2" />

*Disable User Install and add the scope `bot` and the permissions `Attach Files`, `Manage Channels`, `Manage Threads`, `Send Messages`, `Send Messages in Threads`*
<img src="https://raw.githubusercontent.com/mrdotb/i/master/disco-log/12-bot-settings.png" alt="Bot settings" />

*Generate and copy the bot token, it will be needed later*
<img src="https://raw.githubusercontent.com/mrdotb/i/master/disco-log/13-bot-token.png" alt="Bot token" />

## Add Bot to your Server

*Go to the installation menu and open the installation link*
<img src="https://raw.githubusercontent.com/mrdotb/i/master/disco-log/14-install-bot.png" alt="Instal Bot on your server step 1" />
*Follow the steps*
<img src="https://raw.githubusercontent.com/mrdotb/i/master/disco-log/15-install-bot.png" alt="Instal Bot on your server step 2" />
<img src="https://raw.githubusercontent.com/mrdotb/i/master/disco-log/16-install-bot.png" alt="Instal Bot on your server step 3" />
<img src="https://raw.githubusercontent.com/mrdotb/i/master/disco-log/17-install-bot.png" alt="Instal Bot on your server step 4" />


## Create DiscoLog channels

Edit your `config/dev.exs` and add the following configuration with the bot token and the server ID you copied earlier.

```elixir
config :disco_log,
  otp_app: :app_name,
  token: "YOUR_BOT.TOKEN",
  guild_id: "YOUR_SERVER_ID",
```

Run the mix task
```elixir
mix disco_log.create
```

It will create and output the rest of the necessary configuration for you.
Use this configuration for your production environment or add it to your dev config if you just want to test.
