defmodule DiscoLog.Discord.API.Client do
  @moduledoc """
  Default `DiscoLog.Discord.API` implementation.
  """
  @behaviour DiscoLog.Discord.API

  @version DiscoLog.MixProject.project()[:version]

  @impl DiscoLog.Discord.API
  def client(token) do
    client =
      Req.new(
        base_url: "https://discord.com/api/v10",
        headers: [
          {"User-Agent", "DiscoLog (https://github.com/mrdotb/disco-log, #{@version}"}
        ],
        auth: "Bot #{token}"
      )

    %DiscoLog.Discord.API{client: client, module: __MODULE__}
  end

  @impl DiscoLog.Discord.API
  def request(client, method, url, opts) do
    client
    |> Req.merge(
      method: method,
      url: url
    )
    |> Req.merge(opts)
    |> then(fn request ->
      request
      |> Req.Request.fetch_option(:form_multipart)
      |> case do
        {:ok, fields} ->
          Req.merge(request,
            form_multipart: Keyword.update!(fields, :payload_json, &Jason.encode_to_iodata!/1)
          )

        :error ->
          request
      end
    end)
    |> Req.request()
  end
end
