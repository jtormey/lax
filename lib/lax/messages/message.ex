defmodule Lax.Messages.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "messages" do
    field :text, :string

    belongs_to :channel, Lax.Channels.Channel
    belongs_to :sent_by_user, Lax.Users.User

    has_many :link_previews, Lax.Messages.LinkPreview, foreign_key: :resource_id

    field :compact, :boolean, default: false, virtual: true

    timestamps(type: :naive_datetime_usec)
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:text])
    |> validate_required([:text])
  end

  def show_time(message, time_zone) do
    {time_zone, strfmt} =
      if time_zone do
        {time_zone, "%I:%M %p"}
      else
        {"America/New_York", "%I:%M %p (%Z)"}
      end

    strfmt =
      cond do
        message.compact -> "%I:%M"
        before_beggining_of_day?(message.inserted_at) -> "#{strfmt}, %m/%d/%y"
        true -> strfmt
      end

    message.inserted_at
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.shift_zone!(time_zone)
    |> Calendar.strftime(strfmt)
    |> String.trim_leading("0")
  end

  def before_beggining_of_day?(naive_date_time) do
    NaiveDateTime.before?(
      naive_date_time,
      NaiveDateTime.beginning_of_day(NaiveDateTime.utc_now())
    )
  end
end
