defmodule GameMasterCoreWeb.Router do
  use GameMasterCoreWeb, :router

  import GameMasterCoreWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {GameMasterCoreWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :session_api do
    plug :accepts, ["json"]
    plug :fetch_current_scope_for_session_api
  end

  pipeline :require_session_auth do
    plug :require_authenticated_session_api_user
  end

  scope "/", GameMasterCoreWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/token", GameMasterCoreWeb do
    pipe_through :api

    post "/", TokenController, :create
  end

  scope "/api/auth", GameMasterCoreWeb do
    pipe_through :api

    post "/signup", ApiAuthController, :signup
    post "/login", ApiAuthController, :login
  end

  scope "/api/auth", GameMasterCoreWeb do
    pipe_through [:session_api, :require_session_auth]

    delete "/logout", ApiAuthController, :logout
    get "/status", ApiAuthController, :status
  end

  scope "/api", GameMasterCoreWeb do
    pipe_through [:session_api, :require_session_auth, :assign_current_game]

    resources "/games", GameController, except: [:new, :edit] do
      get "/members", GameController, :list_members
      post "/members", GameController, :add_member
      delete "/members/:user_id", GameController, :remove_member

      get "/links", GameController, :list_entities

      resources "/notes", NoteController, except: [:new, :edit] do
        get "/links", NoteController, :list_links
        post "/links", NoteController, :create_link
        delete "/links/:entity_type/:entity_id", NoteController, :delete_link
      end

      resources "/characters", CharacterController, except: [:new, :edit] do
        get "/links", CharacterController, :list_links
        post "/links", CharacterController, :create_link
        delete "/links/:entity_type/:entity_id", CharacterController, :delete_link
      end

      resources "/factions", FactionController, except: [:new, :edit] do
        get "/links", FactionController, :list_links
        post "/links", FactionController, :create_link
        delete "/links/:entity_type/:entity_id", FactionController, :delete_link
      end

      resources "/locations", LocationController, except: [:new, :edit] do
        get "/links", LocationController, :list_links
        post "/links", LocationController, :create_link
        delete "/links/:entity_type/:entity_id", LocationController, :delete_link
      end

      resources "/quests", QuestController, except: [:new, :edit] do
        get "/links", QuestController, :list_links
        post "/links", QuestController, :create_link
        delete "/links/:entity_type/:entity_id", QuestController, :delete_link
      end
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:game_master_core, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: GameMasterCoreWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", GameMasterCoreWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{GameMasterCoreWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", GameMasterCoreWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{GameMasterCoreWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  scope "/admin", GameMasterCoreWeb.Admin do
    pipe_through [:browser, :require_authenticated_user]

    resources "/games", GameController do
      get "/members", GameController, :list_members
      post "/members", GameController, :add_member
      delete "/members/:user_id", GameController, :remove_member

      resources "/notes", NoteController
      resources "/characters", CharacterController
      resources "/factions", FactionController
    end
  end

  scope "/api/swagger" do
    forward "/", PhoenixSwagger.Plug.SwaggerUI,
      otp_app: :game_master_core,
      swagger_file: "swagger.json"
  end

  def swagger_info do
    %{
      info: %{
        version: "1.0",
        title: "Game Master API"
      },
      securityDefinitions: %{
        Bearer: %{
          type: "apiKey",
          name: "Authorization",
          in: "header",
          description: "Bearer token authentication"
        }
      },
      security: [
        %{Bearer: []}
      ]
    }
  end
end
