defmodule LaxWeb.UserRegistrationLive.SwiftUI do
  use LaxNative, [:render_component, format: :swiftui]

  def render(assigns, _) do
    ~LVN"""
    <.header>
      Register
      <:actions>
        <.link navigate={~p"/users/sign-in"} class="font-weight-semibold fg-tint">
          Sign in
        </.link>
      </:actions>
    </.header>

    <.simple_form
      for={@form}
      id="registration_form"
      phx-submit="save"
      phx-change="validate"
      phx-trigger-action={@trigger_submit}
      action={~p"/users/sign-in?_action=registered"}
      method="post"
    >
      <.error :if={@check_errors}>
        Oops, something went wrong! Please check the errors below.
      </.error>

      <.input field={@form[:email]} type="TextField" label="Email" class="keyboardType(.emailAddress)" autocomplete="off" />
      <.input field={@form[:password]} type="SecureField" label="Password" />

      <:actions>
        <.button type="submit">
          Create an account
        </.button>
      </:actions>
    </.simple_form>
    """
  end
end
