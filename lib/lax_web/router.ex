defmodule LaxWeb.Router do
  use LaxWeb, :router

  import LaxWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html", "swiftui"]
    plug :fetch_session
    plug :fetch_live_flash

    plug :put_root_layout,
      html: {LaxWeb.Layouts, :root},
      swiftui: {LaxWeb.Layouts.SwiftUI, :root}

    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LaxWeb do
    get "/health", HealthController, :health
  end

  # Enable Swoosh mailbox preview in development
  if Application.compile_env(:lax, :dev_routes) do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", LaxWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{LaxWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/sign-in", UserLoginLive, :new
      live "/users/reset-password", UserForgotPasswordLive, :new
      live "/users/reset-password/:token", UserResetPasswordLive, :edit
    end

    post "/users/sign-in", UserSessionController, :create
  end

  scope "/", LaxWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{LaxWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm-email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", LaxWeb do
    pipe_through [:browser]

    get "/support", PageController, :support

    get "/users/sign-out", UserSessionController, :delete
    delete "/users/sign-out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{LaxWeb.UserAuth, :mount_current_user}] do
      live "/", ChatLive, :chat
      live "/chat/:id", ChatLive, :chat_selected
      live "/direct-messages", DirectMessageLive, :new
      live "/direct-messages/:id", DirectMessageLive, :show
      live "/new-direct-message", DirectMessageLive.NewDirectMessageLive, :new
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
