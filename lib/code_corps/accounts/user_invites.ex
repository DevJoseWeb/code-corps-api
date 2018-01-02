defmodule CodeCorps.Accounts.UserInvites do
  alias CodeCorps.{Project, ProjectUser, Repo, User, UserInvite}
  alias Ecto.{Changeset, Multi}

  import Ecto.Query

  @spec create_invite(map) :: {:ok, UserInvite.t()} | {:error, Changeset.t()}
  def create_invite(%{} = params) do
    %UserInvite{}
    |> Changeset.cast(params, [:email, :name, :role, :inviter_id, :project_id])
    |> Changeset.validate_required([:email, :inviter_id])
    |> Changeset.validate_inclusion(:role, ProjectUser.roles())
    |> Changeset.assoc_constraint(:inviter)
    |> Changeset.assoc_constraint(:project)
    |> ensure_email_not_owned_by_member()
    |> Repo.insert()
  end

  @spec ensure_email_not_owned_by_member(Changeset.t()) :: Changeset.t()
  defp ensure_email_not_owned_by_member(%Changeset{} = changeset) do
    email = changeset |> Changeset.get_change(:email)
    project_id = changeset |> Changeset.get_change(:project_id)

    case [email, project_id] do
      [nil, _] ->
        changeset

      [_, nil] ->
        changeset

      [email, project_id] ->
        count =
          ProjectUser
          |> where(project_id: ^project_id)
          |> join(:inner, [pu], u in User, pu.user_id == u.id)
          |> where([_pu, u], u.email == ^email)
          |> select([pu, _U], count(pu.id))
          |> Repo.one()

        if count > 0 do
          changeset |> Changeset.add_error(:email, "Already associated with a project member")
        else
          changeset
        end
    end
  end

  @spec claim_invite(map) :: {:ok, User.t()}
  def claim_invite(%{} = params) do
    Multi.new()
    |> Multi.run(:load_invite, fn %{} -> params |> load_invite() end)
    |> Multi.run(:user, fn %{} -> params |> claim_new_user() end)
    |> Multi.run(:project_user, fn %{user: user, load_invite: user_invite} ->
      user |> join_project(user_invite)
    end)
    |> Multi.run(:user_invite, fn %{user: user, load_invite: user_invite} ->
      user_invite |> associate_invitee(user)
    end)
    |> Repo.transaction()
    |> marshall_response()
  end

  @spec load_invite(map) :: {:ok, UserInvite.t()} | {:error, :not_found}
  defp load_invite(%{"invite_id" => invite_id}) do
    case UserInvite |> Repo.get(invite_id) |> Repo.preload([:invitee, :project]) do
      nil -> {:error, :not_found}
      %UserInvite{} = invite -> {:ok, invite}
    end
  end

  defp load_invite(%{}), do: {:error, :not_found}

  @spec claim_new_user(map) :: {:ok, User.t()}
  defp claim_new_user(%{} = params) do
    %User{} |> User.registration_changeset(params) |> Repo.insert()
  end

  @spec join_project(User.t(), UserInvite.t()) :: {:ok, ProjectUser.t()} | {:error, Changeset.t()}
  defp join_project(%User{} = user, %UserInvite{role: role, project: %Project{} = project}) do
    case ProjectUser |> Repo.get_by(user_id: user.id, project_id: project.id) do
      %ProjectUser{} = project_user ->
        {:ok, project_user}

      nil ->
        %ProjectUser{}
        |> Changeset.change(%{role: role})
        |> Changeset.put_assoc(:project, project)
        |> Changeset.put_assoc(:user, user)
        |> Repo.insert()
    end
  end

  defp join_project(%User{}, %UserInvite{}), do: {:ok, nil}

  @spec associate_invitee(UserInvite.t(), User.t()) :: ProjectUser.t()
  defp associate_invitee(%UserInvite{invitee: nil} = invite, %User{} = user) do
    invite
    |> Changeset.change(%{})
    |> Changeset.put_assoc(:invitee, user)
    |> Repo.update()
  end

  @spec marshall_response(tuple) :: tuple
  defp marshall_response({:ok, %{user: user}}), do: {:ok, user |> Repo.preload(:project_users)}
  defp marshall_response({:error, :load_invite, :not_found, _}), do: {:error, :invite_not_found}
  defp marshall_response(other_tuple), do: other_tuple
end
