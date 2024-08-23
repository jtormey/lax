defmodule LaxWeb.UserLive.Components.SwiftUI do
  use LiveViewNative.Component

  attr :user, Lax.Users.User, required: true

  def username(assigns) do
    ~LVN"""
    <Text>
      <%= Lax.Users.User.display_name(@user) %>
    </Text>
    """
  end

  attr :user, Lax.Users.User, required: true
  attr :size, :atom, values: [:xs, :md, :xl]
  attr :online, :boolean, default: nil

  def user_profile(%{size: :xs} = assigns) do
    ~LVN"""
    <ZStack alignment="bottomTrailing">
      <RoundedRectangle
        cornerRadius={6}
        style='fill(attr("display_color")); frame(width: 24, height: 24);'
        display_color={@user.display_color}
      />
      <.online_indicator :if={@online != nil} online={@online} size={@size} />
    </ZStack>
    """
  end

  def user_profile(%{size: :md} = assigns) do
    ~LVN"""
    <ZStack alignment="bottomTrailing">
      <RoundedRectangle
        cornerRadius={8}
        style='fill(attr("display_color")); frame(width: 32, height: 32);'
        display_color={@user.display_color}
      />
      <.online_indicator :if={@online != nil} online={@online} size={@size} />
    </ZStack>
    """
  end

  def user_profile(%{size: :xl} = assigns) do
    ~LVN"""
    <ZStack alignment="bottomTrailing" style="aspectRatio(1, contentMode: .fit);">
      <RoundedRectangle
        cornerRadius={16}
        style='fill(attr("display_color"));'
        display_color={@user.display_color}
      />
      <.online_indicator :if={@online != nil} online={@online} size={@size} />
    </ZStack>
    """
  end

  attr :online, :boolean, required: true
  attr :size, :atom, values: [:xs, :md, :xl]

  defp online_indicator(%{size: :xs} = assigns) do
    ~LVN"""
      <ZStack style='frame(width: 6, height: 6);'>
        <Circle :if={@online == true} style='fill(.green); frame(width: 10, height: 10); overlay(:border); padding(-1);' />
        <Circle :if={@online == false} style='fill(.gray); frame(width: 10, height: 10); overlay(:border); padding(-1);' />
        <Circle style='stroke(.background, lineWidth: 2);' />
      </ZStack>
    """
  end

  defp online_indicator(%{size: :md} = assigns) do
    ~LVN"""
      <ZStack style='frame(width: 10, height: 10);'>
        <Circle :if={@online == true} style='fill(.green); frame(width: 10, height: 10); overlay(:border); padding(-1);' />
        <Circle :if={@online == false} style='fill(.gray); frame(width: 10, height: 10); overlay(:border); padding(-1);' />
        <Circle style='stroke(.background, lineWidth: 2);' />
      </ZStack>
    """
  end

  defp online_indicator(%{size: :xl} = assigns) do
    ~LVN"""
      <ZStack style='frame(width: 32, height: 32);'>
        <Circle :if={@online == true} style='fill(.green); frame(width: 32, height: 32); overlay(:border); padding(-1);' />
        <Circle :if={@online == false} style='fill(.gray); frame(width: 32, height: 32); overlay(:border); padding(-1);' />
        <Circle style='stroke(.background, lineWidth: 4);' />
      </ZStack>
    """
  end
end
