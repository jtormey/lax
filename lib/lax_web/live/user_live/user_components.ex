defmodule LaxWeb.UserLive.UserComponents do
  use LaxWeb, :html

  attr :user, Lax.Users.User, required: true

  def username(assigns) do
    ~H"""
    <span class="text-sm text-white font-bold">
      <%= @user.username %>
    </span>
    """
  end

  attr :user, Lax.Users.User, required: true
  attr :size, :atom, values: [:sm, :md]
  attr :class, :string, default: nil

  def user_profile(assigns) do
    size_class =
      case assigns.size do
        :md -> "size-8 rounded-lg"
      end

    assigns = assign(assigns, :size_class, size_class)

    ~H"""
    <div style={"background-color: #{@user.display_color};"} class={[@size_class, @class]} />
    """
  end
end
