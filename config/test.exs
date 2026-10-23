import Config

config :linea_ui, LineaUI.TestEndpoint,
  secret_key_base: String.duplicate("linea_ui_test_secret_", 4),
  live_view: [signing_salt: "linea_ui_test"],
  render_errors: [formats: [html: LineaUI.TestEndpoint.ErrorHTML]],
  server: false

config :phoenix, :json_library, Jason
config :logger, level: :warning
