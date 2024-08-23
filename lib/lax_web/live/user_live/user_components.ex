defmodule LaxWeb.UserLive.Components do
  use LaxWeb, :html

  attr :user, Lax.Users.User, required: true

  def username(assigns) do
    ~H"""
    <span class="text-sm text-white font-bold">
      <%= Lax.Users.User.display_name(@user) %>
    </span>
    """
  end

  attr :user, Lax.Users.User, required: true
  attr :size, :atom, values: [:xs, :md, :xl]
  attr :class, :string, default: nil
  attr :online, :boolean, default: nil

  def user_profile(assigns) do
    {size_class, indicator_class} =
      case assigns.size do
        :xs -> {"size-4 rounded", "size-1.5"}
        :md -> {"size-8 rounded-lg", "size-2"}
        :xl -> {"size-48 rounded-3xl", "size-4"}
      end

    assigns = assign(assigns, size_class: size_class, indicator_class: indicator_class)

    ~H"""
    <div style={"background-color: #{@user.display_color};"} class={["relative", @size_class, @class]}>
      <div
        :if={@online != nil}
        class={[
          "absolute -bottom-px -right-0.5 rounded-full ring-2 ring-zinc-950",
          @indicator_class,
          if(@online == true, do: "bg-emerald-500"),
          if(@online == false, do: "border border-zinc-500 bg-zinc-950")
        ]}
      />
    </div>
    """
  end
end
