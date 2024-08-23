defmodule Lax.Users.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Lax.Users.UserToken

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :email, :string
    field :username, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :time_zone, :string, default: "America/New_York"
    field :display_color, :string
    field :confirmed_at, :naive_datetime
    field :deleted_at, :naive_datetime
    field :apns_device_token, {:array, :string}, default: []

    embeds_one :ui_settings, UiSettings, on_replace: :update, primary_key: false do
      field :channels_sidebar_width, :integer, default: 250
      field :direct_messages_sidebar_width, :integer, default: 500
      field :profile_sidebar_width, :integer, default: 500
    end

    many_to_many :channels, Lax.Channels.Channel, join_through: Lax.Channels.ChannelUser

    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :username, :password, :time_zone])
    |> validate_email(opts)
    |> validate_username(opts)
    |> validate_password(opts)
    |> validate_time_zone()
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_username(changeset, opts) do
    changeset
    |> validate_required([:username])
    |> validate_length(:username, min: 1, max: 40)
    |> maybe_validate_unique_username(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 72)
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, Lax.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  defp maybe_validate_unique_username(changeset, opts) do
    if Keyword.get(opts, :validate_username, true) do
      changeset
      |> unsafe_validate_unique(:username, Lax.Repo)
      |> unique_constraint(:username)
    else
      changeset
    end
  end

  defp validate_time_zone(changeset) do
    changeset
    |> validate_required([:time_zone])
    |> validate_inclusion(:time_zone, Tzdata.zone_list())
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  def ui_settings_changeset(user, attrs) do
    user
    |> cast(attrs, [])
    |> cast_embed(:ui_settings, with: &ui_settings_embed_changeset/2)
  end

  def ui_settings_embed_changeset(ui_settings, attrs) do
    cast(ui_settings, attrs, [
      :channels_sidebar_width,
      :direct_messages_sidebar_width,
      :profile_sidebar_width
    ])
  end

  def apns_device_token_changeset(user, attrs) do
    user
    |> cast(attrs, [:apns_device_token])
  end

  def delete_changeset(user) do
    system_time = :os.system_time()

    user
    |> change(
      email: "deleted+#{system_time}@lax.so",
      username: "deleted_#{system_time}",
      password: Base.encode64(:crypto.strong_rand_bytes(16)),
      time_zone: "America/New_York",
      display_color: "#71717a",
      ui_settings: nil,
      apns_device_token: [],
      confirmed_at: nil,
      deleted_at: NaiveDateTime.utc_now(:second)
    )
    |> maybe_hash_password(hash_password: true)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Lax.Users.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  ## Queries

  def active_query(query \\ __MODULE__) do
    where(query, [u], is_nil(u.deleted_at))
  end

  ## Multis

  def delete_user_multi(multi, user) do
    multi
    |> Ecto.Multi.update(:user, delete_changeset(user))
    |> Ecto.Multi.delete_all(:user_tokens, UserToken.by_user_and_contexts_query(user, :all))
  end

  ## View

  def display_name(user) do
    if user.deleted_at, do: "Deleted User", else: user.username
  end
end
