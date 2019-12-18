defmodule OpenspotEx.Test do
  require Logger
  use WebSockex

  @hostname "openspot.local"
  @default_password "openspot"
  @json_headers [
    {"Accept", "application/json"},
    {"Content-Type", "application/json"},
    {"Connection", "keep-alive"}
  ]

  def start_link(_args \\ [], state \\ %{}) do
    {:ok, jwt} = authenticate()

    IO.puts("JWT: #{jwt}")
    url = "ws://openspot.local/" <> jwt

    WebSockex.start_link(url, __MODULE__, state,
      extra_headers: [{"Sec-WebSocket-Protocol", "openspot2"}]
    )
  end

  def init() do
    {:ok, jwt} = authenticate()
    url = "ws://openspot.local/" <> jwt

    IO.puts("URL: #{url}")

    {:ok, %{jwt: jwt}}
  end

  @impl true
  def handle_frame({:text, msg}, state) do
    Logger.debug(msg)

    json = Jason.decode!(msg)
    dispatch_msg(json)

    {:ok, state}
  end

  @impl true
  def handle_frame({type, msg}, state) do
    IO.puts("Received type: #{inspect(type)}, msg: #{inspect(msg)}")
    {:ok, state}
  end

  def dispatch_msg(%{"type" => "calllog"} = msg) do
    IO.puts("*****************************")
    IO.puts("Calllog: #{inspect(msg)}")
    IO.puts("*****************************")
  end

  def dispatch_msg(_msg) do
  end

  def authenticate(password \\ @default_password) do
    {:ok, response} = HTTPoison.get(api_url("gettok"))
    {:ok, %{"token" => token}} = Jason.decode(response.body)

    digest = digest_password(password, token)

    login_payload =
      Jason.encode!(%{
        token: token,
        digest: digest
      })

    {:ok, response} = HTTPoison.post(api_url("login"), login_payload, @json_headers)

    {:ok, %{"jwt" => jwt}} = Jason.decode(response.body)

    IO.puts("Got JWT: #{jwt}")

    {:ok, jwt}
  end

  defp api_url(path), do: @hostname <> "/" <> path

  def digest_password(password, token) do
    :crypto.hash(:sha256, token <> password) |> Base.encode16() |> String.downcase()
  end
end
