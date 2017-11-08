defmodule CodeCorps.GitHub.API.PullRequestTest do
  @moduledoc false

  use CodeCorps.DbAccessCase

  alias CodeCorps.{
    GitHub.API.PullRequest
  }

  describe "from_url/2" do
    test "calls github API to create an issue for assigned task, makes user request if user is connected, returns response" do
      url = "https://api.github.com/repos/baxterthehacker/public-repo/pulls/1"
      github_app_installation = insert(:github_app_installation)
      github_repo = insert(:github_repo, github_account_login: "foo", name: "bar", github_app_installation: github_app_installation)

      assert PullRequest.from_url(url, github_repo)
      assert_received({
        :get,
        endpoint_url,
        _body,
        [
          {"Accept", "application/vnd.github.machine-man-preview+json"},
          {"Authorization", "token" <> _tok}
        ],
        _options
      })
      assert endpoint_url == url
    end
  end
end
