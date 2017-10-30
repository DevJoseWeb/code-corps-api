defmodule CodeCorps.GitHub.API do
  alias CodeCorps.{
    GithubAppInstallation,
    GitHub,
    GitHub.API.Pagination,
    GitHub.APIError,
    GitHub.HTTPClientError,
    User
  }

  alias HTTPoison.{Error, Response}

  def gateway(), do: Application.get_env(:code_corps, :github)

  @spec request(GitHub.method, String.t, GitHub.headers, GitHub.body, list) :: GitHub.response
  def request(method, url, body, headers, options) do
    gateway().request(method, url, body, headers, options)
    |> marshall_response()
  end

  @spec get_all(String.t, GitHub.headers, list) :: GitHub.response
  def get_all(url, headers, options) do
    {:ok, %Response{request_url: request_url, headers: response_headers}} =
      gateway().request(:head, url, "", headers, options)

    response_headers
    |> Pagination.retrieve_total_pages()
    |> Pagination.to_page_numbers()
    |> Enum.map(&Pagination.add_page_param(options, &1))
    |> Enum.map(&gateway().request(:get, url, "", headers, &1))
    |> Enum.map(&marshall_response/1)
    |> Enum.map(&Tuple.to_list/1)
    |> Enum.map(&List.last/1)
    |> List.flatten
  end

  @doc """
  Get access token headers for a given `CodeCorps.User` and
  `CodeCorps.GithubAppInstallation`.

  If the user does not have a `github_auth_token` (meaning they are not
  connected to GitHub), then we default to the installation which will post on
  behalf of the user as a bot.
  """
  @spec opts_for(User.t, GithubAppInstallation.t) :: list
  def opts_for(%User{github_auth_token: nil}, %GithubAppInstallation{} = installation) do
    opts_for(installation)
  end
  def opts_for(%User{github_auth_token: token}, %GithubAppInstallation{}) do
    [access_token: token]
  end

  @doc """
  Get access token headers for a given `CodeCorps.GithubAppInstallation`.

  This should only be used in instances where the full permissions of the
  application are needed and there is no need for attribution to a user.
  """
  @spec opts_for(GithubAppInstallation.t) :: list
  def opts_for(%GithubAppInstallation{} = installation) do
    with {:ok, token} <- installation |> GitHub.API.Installation.get_access_token do
      [access_token: token]
    else
      {:error, github_error} -> {:error, github_error}
    end
  end

  @typep http_success :: {:ok, Response.t}
  @typep http_failure :: {:error, term}

  @spec marshall_response(http_success | http_failure) :: GitHub.response
  defp marshall_response({:ok, %Response{body: body, status_code: status}}) when status in 200..299 do
    case body |> Poison.decode do
      {:ok, json} ->
        {:ok, json}
      {:error, _value} ->
        {:error, HTTPClientError.new(reason: :body_decoding_error)}
    end
  end
  defp marshall_response({:ok, %Response{body: body, status_code: 404}}) do
    {:error, APIError.new({404, %{"message" => body}})}
  end
  defp marshall_response({:ok, %Response{body: body, status_code: status}}) when status in 400..599 do
    case body |> Poison.decode do
      {:ok, json} ->
        {:error, APIError.new({status, json})}
      {:error, _value} ->
        {:error, HTTPClientError.new(reason: :body_decoding_error)}
    end
  end
  defp marshall_response({:error, %Error{reason: reason}}) do
    {:error, HTTPClientError.new(reason: reason)}
  end
  defp marshall_response({:error, reason}) do
    {:error, HTTPClientError.new(reason: reason)}
  end
end
