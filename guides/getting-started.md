# Getting Started

This guide is an introduction to DiscoLog. It will guide you through the setup of DiscoLog and how to use it.

## Install DiscoLog

The first step to add DiscoLog to your application is to declare the package as a dependency in your `mix.exs` file.

```elixir
defp deps do
  [
    {:disco_log, "~> 1.0.3"}
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

![Create Server step 1](assets/001.png)
![Create Server step 2](assets/002.png)
![Create Server step 3](assets/003.png)

### Edit the Discord Server settings

*Right-click on the server and select `Server Settings` > `Community Settings`*
![Edit Server step 4](assets/004.png)
![Edit Server step 5](assets/005.png)
![Edit Server step 6](assets/006.png)
![Edit Server step 7](assets/007.png)
![Edit Server step 8](assets/008.png)

*Copy the server ID, it will be needed later*

+*If you don't see `Copy Server ID` in the UI, enable developer mode in Settings -> Advanced -> Developer Mode.*

![Edit Server step 9](assets/009.png)

## Create a Discord Bot

Go to the [developers portal](https://discord.com/developers/applications)

![Create bot 1](assets/010.png)
![Create bot 2](assets/011.png)

*Disable User Install and add the scope `bot` and the permissions `Attach Files`, `Manage Channels`, `Manage Threads`, `Send Messages`, `Send Messages in Threads`*
![Bot settings](assets/012.png)

*Generate and copy the bot token, it will be needed later*
![Bot token](assets/013.png)

## Add Bot to your Server

*Go to the installation menu and open the installation link*

![Install Bot on your server step 1](assets/014.png)

*Follow the steps*

![Install Bot on your server step 2](assets/015.png)
![Install Bot on your server step 3](assets/016.png)
![Install Bot on your server step 4](assets/017.png)


## Create DiscoLog channels

Edit your `config/dev.exs` and add the following configuration with the bot token and the server ID you copied earlier.

```elixir
config :disco_log,
  otp_app: :app_name,
  token: "YOUR_BOT.TOKEN",
  guild_id: "YOUR_SERVER_ID",
  category_id: "",
  occurrences_channel_id: "",
  info_channel_id: "",
  error_channel_id: ""
```

Run the mix task
```elixir
mix disco_log.create
```

It will create and output the rest of the necessary configuration for you.
Use this configuration for your production environment or add it to your dev config if you want to test.

Confirm that everything is working smoothly by running the following mix command it will put a log in each channels.
```elixir
mix disco_log.sample
```

*How it should look like*

![Sample log 1](assets/018.png)
![Sample log 2](assets/019.png)


## After setup

When you confirmed that the setup is working you should put this config to disable DiscoLog in `dev.exs` and `test.exs` env.

```elixir
config :disco_log,
  enable: false
```

## Presence Status

DiscoLog can optionally set your bot's status to **Online**, allowing you to display a custom presence message. 

### Steps to Enable Presence Status

1. **Add the `mint_web_socket` Package**  
   Update your dependencies in `mix.exs`:

   ```elixir
   defp deps do
     [
       {:disco_log, "~> 1.0.0"},
       {:mint_web_socket, "~> 1.0"}
     ]
   end
   ```

2. **Configure the Presence Settings**  
   Add the following to your `config.exs` or `prod/config.exs`:

   ```elixir
   config :disco_log,
     enable_presence: true,
     presence_status: "🪩 Disco Logging" # Optional, defaults to this value
   ```

*Bot with Presence*

![Presence status](assets/presence.png)

## Go to Repo Feature

The **Go to Repo** feature allows DiscoLog to link directly to your code repository (e.g., GitHub). This enables users to easily access the specific version of the code related to a log entry.

### Example Interface
*Link to GitHub code*
![Go to code](assets/go-to-code.png)

### Configuration Instructions

To enable this feature, add the following configuration to your `prod/config.exs`:

```elixir
config :disco_log,
  enable_go_to_repo: true,
  go_to_repo_top_modules: ["DemoWeb"], # Optional, see notes below
  repo_url: "https://github.com/mrdotb/disco-log/blob",
  git_sha: System.fetch_env!("GIT_SHA") # See notes on setting the GIT_SHA below
```

### Setting the `GIT_SHA`

The `GIT_SHA` should be the commit hash of the current code version. This ensures links reference the correct version of the code. Here’s how you can set it, depending on your deployment process:

#### 1. **Bare Metal Deployments**
If you build your release on your own machine, you can set the environment variable using this command:

```bash
GIT_SHA=`git rev-parse HEAD` MIX_ENV=prod mix release
```

#### 2. **Docker Deployments**
When building a Docker image, pass the `GIT_SHA` as a build argument:

**Build Command**:
```bash
docker build --build-arg GIT_SHA=`git rev-parse HEAD` .
```

**Dockerfile**:
```Dockerfile
ARG GIT_SHA

# Set build environment variables
ENV MIX_ENV="prod"
ENV GIT_SHA=${GIT_SHA}
```

#### 3. **CI/CD Pipelines**
In CI/CD environments (e.g., GitHub Actions), the `GIT_SHA` is often available as a predefined environment variable. You can pass it during the build process as follows:

**Example GitHub Actions Workflow**:
```yaml
- name: Build and Push Docker Image to GHCR
  uses: docker/build-push-action@v5
  with:
    context: .
    push: true
    tags: ${{ steps.meta.outputs.tags }}
    labels: ${{ steps.meta.outputs.labels }}
    build-args: |
      BUILD_METADATA=${{ steps.meta.outputs.json }}
      ERL_FLAGS=+JPperf true
      GIT_SHA=${{ github.sha }}
```

### Notes
- The `repo_url` configuration should point to the root of your repository's code (e.g., `https://github.com/<user>/<repo>/blob`).
- The `go_to_repo_top_modules` configuration is optional. Use it only if your project contains external modules within the repository.

Enjoy using DiscoLog!
