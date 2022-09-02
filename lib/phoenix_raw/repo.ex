defmodule PhoenixRaw.Repo do
  use Ecto.Repo,
    otp_app: :phoenix_raw,
    adapter: Ecto.Adapters.Postgres
end
