defmodule OpenspotEx.Test do
  @hostname "openspot.local"
  @json_headers [{"Accept", "application/json"}, {"Content-Type", "application/json"}, {"Connection", "keep-alive"}]

  def authenticate(username \\ "openspot", password \\ "openspot") do
    {:ok, response} = HTTPoison.get(api_url("gettok"))
    {:ok, %{"token" => token}} = Jason.decode(response.body)

    IO.puts "Got token: #{token}"

    digest = digest_password("openspot", token)

    IO.puts "Digest: #{digest}" 

    login_body = Jason.encode!(%{
      token: token,
      digest: digest
    })

    IO.puts "Posting login body:"
    IO.puts login_body

    {:ok, response} = HTTPoison.post(api_url("login"), login_body, @json_headers)

    IO.puts "********"
    IO.puts "HTTP Response code: #{response.status_code}"
    IO.inspect response
  end

  defp api_url(path), do: @hostname <> "/" <> path

  def digest_password(password, token) do
    :crypto.hash(:sha256, token <> password) |> Base.encode16() |> String.downcase()
  end

  defp authenticated_json_headers(token) do
  end

end
