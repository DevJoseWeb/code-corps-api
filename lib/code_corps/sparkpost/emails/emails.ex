defmodule CodeCorps.SparkPost.Emails do
  alias CodeCorps.SparkPost.{API, Emails}

  def send_forgot_password_email(user, token) do
    user |> Emails.ForgotPassword.build(token) |> API.send_transmission
  end

  def send_message_initiated_by_project_email(message, conversation) do
    message
    |> Emails.MessageInitiatedByProject.build(conversation)
    |> API.send_transmission
  end

  def send_organization_invite_email(invite) do
    invite |> Emails.OrganizationInvite.build |> API.send_transmission
  end

  def send_project_approval_request_email(project) do
    project |> Emails.ProjectApprovalRequest.build |> API.send_transmission
  end

  def send_project_approved_email(project) do
    project |> Emails.ProjectApproved.build |> API.send_transmission
  end

  def send_project_user_acceptance_email(project_user) do
    project_user |> Emails.ProjectUserAcceptance.build |> API.send_transmission
  end

  def send_project_user_request_email(project_user) do
    project_user |> Emails.ProjectUserRequest.build |> API.send_transmission
  end

  def send_receipt_email(charge, invoice) do
    case charge |> Emails.Receipt.build(invoice) do
      %SparkPost.Transmission{} = transmission ->
        transmission |> API.send_transmission
      build_failure -> build_failure
    end
  end

  def send_reply_to_conversation_email(part, user) do
    part |> Emails.ReplyToConversation.build(user) |> API.send_transmission
  end
end
