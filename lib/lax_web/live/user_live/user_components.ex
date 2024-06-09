defmodule LaxWeb.UserLive.Components do
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
  attr :size, :atom, values: [:xs, :md]
  attr :class, :string, default: nil
  attr :online, :boolean, default: nil

  def user_profile(assigns) do
    size_class =
      case assigns.size do
        :xs -> "size-4 rounded"
        :md -> "size-8 rounded-lg"
      end

    assigns = assign(assigns, :size_class, size_class)

    ~H"""
    <div style={"background-color: #{@user.display_color};"} class={["relative", @size_class, @class]}>
      <div
        :if={@online != nil}
        class={[
          "absolute -bottom-px -right-0.5 rounded-full size-1.5 ring-2 ring-zinc-950",
          if(@online == true, do: "bg-emerald-500"),
          if(@online == false, do: "border border-zinc-500 bg-zinc-950")
        ]}
      />
    </div>
    """
  end
end
