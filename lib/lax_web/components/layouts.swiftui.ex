defmodule LaxWeb.Layouts.SwiftUI do
  use LaxNative, [:layout, format: :swiftui]

  embed_templates "layouts_swiftui/*"
end
