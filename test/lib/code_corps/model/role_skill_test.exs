defmodule CodeCorps.RoleSkillTest do
  use CodeCorps.ModelCase

  alias CodeCorps.RoleSkill

  test "create_changeset with valid attributes" do
    role_id = insert(:role).id
    skill_id = insert(:skill).id

    changeset = RoleSkill.create_changeset(%RoleSkill{}, %{role_id: role_id, skill_id: skill_id})
    assert changeset.valid?
  end

  test "create_changeset requires role_id" do
    skill_id = insert(:skill).id

    changeset = RoleSkill.create_changeset(%RoleSkill{}, %{skill_id: skill_id})

    refute changeset.valid?
    assert_error_message(changeset, :role_id, "can't be blank")
  end

  test "create_changeset requires skill_id" do
    role_id = insert(:role).id

    changeset = RoleSkill.create_changeset(%RoleSkill{}, %{role_id: role_id})

    refute changeset.valid?
    assert_error_message(changeset, :skill_id, "can't be blank")
  end

  test "create_changeset requires id of actual role" do
    role_id = -1
    skill_id = insert(:skill).id

    {result, changeset} =
      RoleSkill.create_changeset(%RoleSkill{}, %{role_id: role_id, skill_id: skill_id})
      |> Repo.insert

    assert result == :error
    refute changeset.valid?
    assert_error_message(changeset, :role, "does not exist")
  end

  test "create_changeset requires id of actual skill" do
    role_id = insert(:role).id
    skill_id = -1

    {result, changeset} =
      RoleSkill.create_changeset(%RoleSkill{}, %{role_id: role_id, skill_id: skill_id})
      |> Repo.insert

    assert result == :error
    refute changeset.valid?
    assert_error_message(changeset, :skill, "does not exist")
  end

  describe "import_changeset" do
    test "valid cat value included in cats is accepted" do
      role_id = insert(:role).id
      skill_id = insert(:skill).id
      cat_value = 1

      changeset = RoleSkill.import_changeset(%RoleSkill{}, %{role_id: role_id, skill_id: skill_id, cat: cat_value})
      assert changeset.valid?
    end

    test "invalid cat value not included in cats is rejected" do
      role_id = insert(:role).id
      skill_id = insert(:skill).id
      cat_value = 9

      changeset = RoleSkill.import_changeset(%RoleSkill{}, %{role_id: role_id, skill_id: skill_id, cat: cat_value})
      refute changeset.valid?
      assert_error_message(changeset, :cat, "is invalid")
    end
  end
end
