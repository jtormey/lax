defmodule LaxWeb.DirectMessageLive.Components do
  use LaxWeb, :html

  def empty_state(assigns) do
    ~H"""
    <div class="flex-1 flex items-center justify-center">
      <span class="text-xl text-zinc-500 font-semibold">
        Select a direct message to chat.
      </span>
    </div>
    """
  end
end
