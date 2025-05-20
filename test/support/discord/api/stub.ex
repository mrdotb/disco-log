defmodule DiscoLog.Discord.API.Stub do
  @moduledoc """
  A collection of canned API responses used as default stubs for `DiscoLog.Discord.API.Mock`
  """
  @behaviour DiscoLog.Discord.API

  @impl DiscoLog.Discord.API
  def client(_token),
    do: %DiscoLog.Discord.API{client: :stub_client, module: DiscoLog.Discord.API.Mock}

  @impl DiscoLog.Discord.API
  def request(_client, :get, "/gateway/bot", _opts) do
    {:ok,
     %{
       status: 200,
       headers: %{},
       body: %{
         "session_start_limit" => %{
           "max_concurrency" => 1,
           "remaining" => 988,
           "reset_after" => 3_297_000,
           "total" => 1000
         },
         "shards" => 1,
         "url" => "wss://gateway.discord.gg"
       }
     }}
  end

  def request(_client, :get, "/guilds/:guild_id/threads/active", _opts) do
    {:ok,
     %{
       status: 200,
       headers: %{},
       body: %{
         "has_more" => false,
         "members" => [],
         "threads" => [
           %{
             "applied_tags" => ["1306066065390043156", "1306066121325285446"],
             "bitrate" => 64_000,
             "flags" => 0,
             "guild_id" => "1302395532735414282",
             "id" => "stub_thread_id",
             "last_message_id" => "1327070193624547442",
             "member_count" => 1,
             "message_count" => 1,
             "name" => "FNGRPT Elixir.RuntimeError",
             "owner_id" => "1302396835582836757",
             "parent_id" => "stub_occurrences_channel_id",
             "rate_limit_per_user" => 0,
             "rtc_region" => nil,
             "thread_metadata" => %{
               "archive_timestamp" => "2025-01-10T00:23:09.502000+00:00",
               "archived" => false,
               "auto_archive_duration" => 4320,
               "create_timestamp" => "2025-01-10T00:23:09.502000+00:00",
               "locked" => false
             },
             "total_message_sent" => 1,
             "type" => 11,
             "user_limit" => 0
           },
           %{
             "applied_tags" => ["1306066065390043156", "1306066121325285446"],
             "bitrate" => 64_000,
             "flags" => 0,
             "guild_id" => "1302395532735414282",
             "id" => "stub_thread_id",
             "last_message_id" => "1327070193624547442",
             "member_count" => 1,
             "message_count" => 1,
             "name" => "Non-DiscoLog Thread",
             "owner_id" => "1302396835582836757",
             "parent_id" => "stub_occurrences_channel_id",
             "rate_limit_per_user" => 0,
             "rtc_region" => nil,
             "thread_metadata" => %{
               "archive_timestamp" => "2025-01-10T00:23:09.502000+00:00",
               "archived" => false,
               "auto_archive_duration" => 4320,
               "create_timestamp" => "2025-01-10T00:23:09.502000+00:00",
               "locked" => false
             },
             "total_message_sent" => 1,
             "type" => 11,
             "user_limit" => 0
           }
         ]
       }
     }}
  end

  def request(_client, :get, "/channels/:channel_id", _opts) do
    {:ok,
     %{
       status: 200,
       headers: %{},
       body: %{
         "available_tags" => [
           %{
             "emoji_id" => nil,
             "emoji_name" => nil,
             "id" => "stub_plug_tag_id",
             "moderated" => false,
             "name" => "plug"
           },
           %{
             "emoji_id" => nil,
             "emoji_name" => nil,
             "id" => "stub_live_view_tag_id",
             "moderated" => false,
             "name" => "live_view"
           },
           %{
             "emoji_id" => nil,
             "emoji_name" => nil,
             "id" => "stub_oban_tag_id",
             "moderated" => false,
             "name" => "oban"
           }
         ],
         "default_forum_layout" => 0,
         "default_reaction_emoji" => nil,
         "default_sort_order" => nil,
         "flags" => 0,
         "guild_id" => "1302395532735414282",
         "icon_emoji" => nil,
         "id" => "1306065664909512784",
         "last_message_id" => "1327070191821131865",
         "name" => "occurrences",
         "nsfw" => false,
         "parent_id" => "1306065439398428694",
         "permission_overwrites" => [],
         "position" => 11,
         "rate_limit_per_user" => 0,
         "template" => "",
         "theme_color" => nil,
         "topic" => nil,
         "type" => 15
       }
     }}
  end

  def request(_client, :post, "/channels/:channel_id/messages", _opts) do
    {:ok,
     %{
       status: 200,
       headers: %{},
       body: %{
         "attachments" => [],
         "author" => %{
           "accent_color" => nil,
           "avatar" => nil,
           "avatar_decoration_data" => nil,
           "banner" => nil,
           "banner_color" => nil,
           "bot" => true,
           "clan" => nil,
           "discriminator" => "9087",
           "flags" => 0,
           "global_name" => nil,
           "id" => "1302396835582836757",
           "primary_guild" => nil,
           "public_flags" => 0,
           "username" => "Disco Log"
         },
         "channel_id" => "1306065758723379293",
         "components" => [],
         "content" => "Hello, World!",
         "edited_timestamp" => nil,
         "embeds" => [],
         "flags" => 0,
         "id" => "1327747295587995708",
         "mention_everyone" => false,
         "mention_roles" => [],
         "mentions" => [],
         "pinned" => false,
         "timestamp" => "2025-01-11T21:13:43.620000+00:00",
         "tts" => false,
         "type" => 0
       }
     }}
  end

  def request(_client, :post, "/channels/:channel_id/threads", _opts) do
    {:ok,
     %{
       status: 201,
       headers: %{},
       body: %{
         "bitrate" => 64_000,
         "flags" => 0,
         "guild_id" => "1302395532735414282",
         "id" => "1327765635022852098",
         "last_message_id" => "1327765635022852098",
         "member" => %{
           "flags" => 1,
           "id" => "1327765635022852098",
           "join_timestamp" => "2025-01-11T22:26:36.114358+00:00",
           "mute_config" => nil,
           "muted" => false,
           "user_id" => "1302396835582836757"
         },
         "member_count" => 1,
         "message" => %{
           "attachments" => [],
           "author" => %{
             "accent_color" => nil,
             "avatar" => nil,
             "avatar_decoration_data" => nil,
             "banner" => nil,
             "banner_color" => nil,
             "bot" => true,
             "clan" => nil,
             "discriminator" => "9087",
             "flags" => 0,
             "global_name" => nil,
             "id" => "1302396835582836757",
             "primary_guild" => nil,
             "public_flags" => 0,
             "username" => "Disco Log"
           },
           "channel_id" => "1327765635022852098",
           "components" => [],
           "content" =>
             "**At:** <t:1736634391:T>\n  **Kind:** ``\n  **Reason:** ``\n  **Source Line:** ``\n  **Source Function:** ``\n  **Fingerprint:** `foo`",
           "edited_timestamp" => nil,
           "embeds" => [],
           "flags" => 0,
           "id" => "1327765635022852098",
           "mention_everyone" => false,
           "mention_roles" => [],
           "mentions" => [],
           "pinned" => false,
           "position" => 0,
           "timestamp" => "2025-01-11T22:26:36.082000+00:00",
           "tts" => false,
           "type" => 0
         },
         "message_count" => 0,
         "name" => "foo",
         "owner_id" => "1302396835582836757",
         "parent_id" => "1306065664909512784",
         "rate_limit_per_user" => 0,
         "rtc_region" => nil,
         "thread_metadata" => %{
           "archive_timestamp" => "2025-01-11T22:26:36.082000+00:00",
           "archived" => false,
           "auto_archive_duration" => 4320,
           "create_timestamp" => "2025-01-11T22:26:36.082000+00:00",
           "locked" => false
         },
         "total_message_sent" => 0,
         "type" => 11,
         "user_limit" => 0
       }
     }}
  end
end
