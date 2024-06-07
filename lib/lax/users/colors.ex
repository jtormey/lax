defmodule Lax.Users.Colors do
  @doc """
  All 400-level colors from the TailwindCSS default palette.

      https://tailwindcss.com/docs/customizing-colors#default-color-palette

  """
  def colors() do
    [
      "#94a3b8",
      "#9ca3af",
      "#a1a1aa",
      "#a3a3a3",
      "#a8a29e",
      "#f87171",
      "#fb923c",
      "#fbbf24",
      "#facc15",
      "#a3e635",
      "#4ade80",
      "#34d399",
      "#2dd4bf",
      "#22d3ee",
      "#38bdf8",
      "#60a5fa",
      "#818cf8",
      "#a78bfa",
      "#c084fc",
      "#e879f9",
      "#f472b6",
      "#fb7185"
    ]
  end

  def random() do
    Enum.random(colors())
  end
end
