defmodule LaxWeb.DirectMessageLive.NewDirectMessageLive.SwiftUI do
  use LaxNative, [:render_component, format: :swiftui]

  import LaxWeb.DirectMessageLive.Components.SwiftUI

  def render(assigns, _interface) do
    ~LVN"""
    hello, world!
    """
  end
end
