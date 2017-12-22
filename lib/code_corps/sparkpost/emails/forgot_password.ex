defmodule CodeCorps.SparkPost.Emails.ForgotPassword do
  alias CodeCorps.{User, WebClient}
  alias SparkPost.{Content, Transmission}

  @spec build(User.t, String.t) :: %Transmission{}
  def build(%User{} = user, token) do
    %Transmission{
      content: %Content.TemplateRef{template_id: "forgot-password"},
      options: %Transmission.Options{inline_css: true},
      recipients: [%{name: user.first_name, email: user.email}],
      substitution_data: %{
        from_name: "Code Corps",
        from_email: "team@codecorps.org",
        link: link(token),
        subject: "Here's the link to reset your password"
      }
    }
  end

  @spec link(String.t) :: String.t
  defp link(token) do
    WebClient.url()
    |> URI.merge("password/reset?token=#{token}")
    |> URI.to_string
  end
end
