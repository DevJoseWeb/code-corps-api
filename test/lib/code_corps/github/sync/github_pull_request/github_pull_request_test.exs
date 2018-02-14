defmodule CodeCorps.GitHub.Sync.GithubPullRequestTest do
  @moduledoc false

  use CodeCorps.DbAccessCase

  import CodeCorps.GitHub.TestHelpers

  alias CodeCorps.{
    GitHub.Sync,
    GitHub.Adapters,
    GithubPullRequest,
    Repo
  }
  @payload load_event_fixture("pull_request_opened")

  describe "create_or_update_pull_request/1" do
    test "creates pull request if none exists" do
      %{"pull_request" => attrs} = @payload
      github_repo = insert(:github_repo)
      {:ok, %GithubPullRequest{} = created_pull_request} =
        Sync.GithubPullRequest.create_or_update_pull_request(attrs, github_repo)

      assert Repo.one(GithubPullRequest)

      created_attributes =
        attrs
        |> Adapters.PullRequest.from_api()
        |> Map.delete(:closed_at)
        |> Map.delete(:merge_commit_sha)
        |> Map.delete(:merged_at)
      returned_pull_request = Repo.get_by(GithubPullRequest, created_attributes)
      assert returned_pull_request.id == created_pull_request.id
      assert returned_pull_request.github_repo_id == github_repo.id
    end

    test "updates pull request if it already exists" do
      %{"pull_request" => %{"id" => pull_request_id} = attrs} = @payload

      github_repo = insert(:github_repo)
      pull_request = insert(:github_pull_request, github_id: pull_request_id, github_repo: github_repo)

      {:ok, %GithubPullRequest{} = updated_pull_request} =
        Sync.GithubPullRequest.create_or_update_pull_request(attrs, github_repo)

      assert updated_pull_request.id == pull_request.id
      assert updated_pull_request.github_repo_id == github_repo.id
    end

    test "returns changeset if payload is somehow not as expected" do
      bad_payload = @payload |> put_in(["pull_request", "number"], nil)
      %{"pull_request" => attrs} = bad_payload
      github_repo = insert(:github_repo)

      {:error, changeset} =
        Sync.GithubPullRequest.create_or_update_pull_request(attrs, github_repo)
      refute changeset.valid?
    end
  end
end
