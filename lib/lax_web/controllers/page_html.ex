defmodule LaxWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use LaxWeb, :html

  embed_templates "page_html/*"

  def privacy_url() do
    "https://github.com/jtormey/lax/blob/main/native/swiftui/PRIVACY_POLICY.md"
  end

  def terms_url() do
    "https://github.com/jtormey/lax/blob/main/native/swiftui/TERMS.md"
  end
end
