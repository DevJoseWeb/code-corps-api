defmodule CodeCorps.Policy.TaskSkillTest do
  @moduledoc false

  use CodeCorps.PolicyCase

  import CodeCorps.Policy.TaskSkill, only: [create?: 2, delete?: 2]

  describe "create?" do
    test "returns false when user is not member of project" do
      user = insert(:user)
      task = insert(:task)

      params = %{"task_id" =>  task.id}
      refute create?(user, params)
    end

    test "returns false when user is pending member of project" do
      %{project: project, user: user} = insert(:project_user, role: "pending")
      task = insert(:task, project: project)

      params = %{"task_id" => task.id}
      refute create?(user, params)
    end

    test "returns true when user is contributor of project" do
      %{project: project, user: user} = insert(:project_user, role: "contributor")
      task = insert(:task, project: project)

      params = %{"task_id" => task.id}
      assert create?(user, params)
    end

    test "returns true when user is admin of project" do
      %{project: project, user: user} = insert(:project_user, role: "admin")
      task = insert(:task, project: project)

      params = %{"task_id" => task.id}
      assert create?(user, params)
    end

    test "returns true when user is owner of project" do
      %{project: project, user: user} = insert(:project_user, role: "owner")
      task = insert(:task, project: project)

      params = %{"task_id" => task.id}
      assert create?(user, params)
    end

    test "returns true when user is author of task" do
      user = insert(:user)
      task = insert(:task, user: user)

      params = %{"task_id" => task.id}

      assert create?(user, params)
    end
  end

  describe "delete?" do
    test "returns false when user is not member of project" do
      user = insert(:user)
      task = insert(:task)

      task_skill = insert(:task_skill, task: task)

      refute delete?(user, task_skill)
    end

    test "returns false when user is pending member of project" do
      %{project: project, user: user} = insert(:project_user, role: "pending")
      task = insert(:task, project: project)

      task_skill = insert(:task_skill, task: task)

      refute delete?(user, task_skill)
    end

    test "returns true when user is contributor of project" do
      %{project: project, user: user} = insert(:project_user, role: "contributor")
      task = insert(:task, project: project)

      task_skill = insert(:task_skill, task: task)

      assert delete?(user, task_skill)
    end

    test "returns true when user is admin of project" do
      %{project: project, user: user} = insert(:project_user, role: "admin")
      task = insert(:task, project: project)

      task_skill = insert(:task_skill, task: task)

      assert delete?(user, task_skill)
    end

    test "returns true when user is owner of project" do
      %{project: project, user: user} = insert(:project_user, role: "owner")
      task = insert(:task, project: project)

      task_skill = insert(:task_skill, task: task)

      assert delete?(user, task_skill)
    end

    test "returns true when user is author of task" do
      user = insert(:user)
      task = insert(:task, user: user)

      task_skill = insert(:task_skill, task: task)

      assert delete?(user, task_skill)
    end
  end
end
