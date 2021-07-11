defmodule Contentful do
  @moduledoc """
  The [Contentful](https://contentful.com) SDK provides helper functions and structs for a subset of the the available
  [Contentful APIs](https://www.contentful.com/developers/docs/references/) and serves as a container
  for the shared structs.

  The available Contentful APIs are:

    * `Contentful.Delivery` - wraps the [Content Delivery API (CDA)](https://www.contentful.com/developers/docs/references/content-delivery-api/) - for accessing production ready content
    * `Contentful.Preview` - wraps the [Content Preview API (CPA)](https://www.contentful.com/developers/docs/references/content-preview-api/) - for accessing drafts prepublication
    * `Contentful.Management` - wraps the [Content Management API (CMA)](https://www.contentful.com/developers/docs/references/content-management-api/) - for managing your content


  ## Setup

  In order to add the Contentful SDK add the following to your `mix.exs`:

  ```
  # mix.exs

  def deps do
    [
      # your other dependencies, then add:
      {:contentful, "~> 0.4"}
    ]
  end
  ```

  You can configure your access token(s) and Contentful environments via your local
  config.exs:

  ```
  # in config.exs
  config :contentful, json_library: Poison # optional, as Jason is the default

  # per API definition:

  config :contentful, delivery: [
    space_id: "<my_space_id>",
    access_token: "<my_cda_token>",
    environment: "<my_environment>" # defaults to `master`
  ]

  config :contentful, management: [
    coming: :soon
  ]

  config :contentful, preview: [
    coming: :soon
  ]
  ```
  Please note that the default `json_library` that this SDK is tested with is `Jason`, yet `Poison`
  should be compatible.
  """

  @doc """
  The JSON library to use. Can be either configured to `Jason` or `Poison`.

  ## Examples

      # in config/config.exs
      config :contentful, json_library: Jason

      iex> Contentful.json_library()
      Jason

  """
  @spec json_library() :: module()
  def json_library do
    case Application.get_env(:contentful, :json_library) do
      nil -> Jason
      lib -> lib
    end
  end

  @doc """
  The `Tesla.client` module to use.

  By default, Contentful uses the standard `Tesla.client`. This can be
  overridden in config to use a custom dynamic client so that
  behaviour can be modified in runtime.

  ## Examples
      # in lib/myapp/logging_client.ex
      defmodule LoggingClient do
        # build dynamic client based on runtime arguments
        def client do
          middleware = [
            {Tesla.Middleware.Logger, debug: false}
          ]
          Tesla.client(middleware)
        end
      end

      # in config/config.exs
      config :contentful, http_client: LoggingClient
  """
  @spec http_client() :: module()
  def http_client do
    case Application.get_env(:contentful, :http_client) do
      nil -> Tesla
      lib -> lib
    end
  end
end
