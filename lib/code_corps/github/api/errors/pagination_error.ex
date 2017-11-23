defmodule CodeCorps.GitHub.API.Errors.PaginationError do
  alias CodeCorps.GitHub.{HTTPClientError, APIError}

  @type t :: %__MODULE__{
    message: String.t,
    api_errors: list,
    client_errors: list,
    retrieved_pages: list
  }

  defstruct [
    message: "One or more pages failed to retrieve during a GitHub API Pagination Request",
    retrieved_pages: [],
    client_errors: [],
    api_errors: []
  ]

  def new({pages, errors}) do
    %__MODULE__{
      retrieved_pages: pages,
      client_errors: errors |> Enum.filter(&client_error?/1),
      api_errors: errors |> Enum.filter(&api_error?/1)
    }
  end

  defp client_error?(%HTTPClientError{}), do: true
  defp client_error?(_), do: false
  defp api_error?(%APIError{}), do: true
  defp api_error?(_), do: false
end
