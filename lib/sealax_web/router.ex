defmodule SealaxWeb.Router do
  use SealaxWeb, :router
  alias Plug.Conn

  import AuthToken.Plug

  @doc "Minimum request time in µs"
  @minimum_request_time 200_000

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth_api do
    plug :accepts, ["json"]
    plug :request_timer, @minimum_request_time
  end

  @doc """
  Pipeline for restricted routes, checks access token
  """
  pipeline :auth do
    plug :verify_token
  end

  scope "/api", SealaxWeb do
    pipe_through :api
    pipe_through :auth
  end

  scope "/auth", SealasWeb do
    pipe_through :auth_api
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through [:fetch_session, :protect_from_forgery]
      live_dashboard "/dashboard", metrics: SealaxWeb.Telemetry
    end
  end

  @doc """
  Registers a function to check time used to handle request.
  Subtracts time taken from @minimum_request_time and waits for $result ms
  """
  @spec request_timer(Plug.Conn.t, integer) :: Plug.Conn.t
  def request_timer(conn, minimum_request_time \\ 200_000) do
    time = Time.utc_now()

    Conn.register_before_send(conn, fn conn ->
      diff = Time.diff(Time.utc_now(), time, :microsecond)

      if diff < minimum_request_time, do: :timer.sleep round((minimum_request_time - diff)/1000)
      conn
    end)
  end
end
