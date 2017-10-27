defmodule CodeCorpsWeb.SkillViewTest do
  use CodeCorpsWeb.ViewCase

  test "renders all attributes and relationships properly" do
    skill = insert(:skill)
    role_skill = insert(:role_skill, skill: skill)

    skill = CodeCorpsWeb.SkillController.preload(skill)
    rendered_json = render(CodeCorpsWeb.SkillView, "show.json-api", data: skill)

    expected_json = %{
      "data" => %{
        "attributes" => %{
          "description" => skill.description,
          "inserted-at" => skill.inserted_at,
          "title" => skill.title,
          "updated-at" => skill.updated_at,
        },
        "id" => skill.id |> Integer.to_string,
        "relationships" => %{
          "role-skills" => %{
            "data" => [
              %{"id" => role_skill.id |> Integer.to_string, "type" => "role-skill"}
            ]
          }
        },
        "type" => "skill",
      },
      "jsonapi" => %{
        "version" => "1.0"
      }
    }

    assert rendered_json == expected_json
  end
end
