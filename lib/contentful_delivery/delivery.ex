defmodule Contentful.Delivery do
  @moduledoc """
  The Delivery API is the main access point for fetching data for your customers.
  The API is _read only_.

  If you wish to manipulate data, please have a look at the `Contentful.Management`.

  ## Basic interaction

  The `space_id`, the `environment` and your `access_token` can all be configured in
  `config/config.exs`:

  ```
  # config/config.exs
  config :contentful, delivery: [
    space_id: "<my_space_id>",
    environment: "<my_environment>",
    access_token: "<my_access_token_cda>"
  ]
  ```

  The space can then be fetched as a `Contentful.Space` via a simple query:

  ```
  import Contentful.Query
  alias Contentful.Delivery.Spaces

  {:ok, space} = Spaces |> fetch_one
  ```

  Retrieving items is then just a matter of importing `Contentful.Query`:

  ```
  import Contentful.Query
  alias Contentful.Delivery.Entries

  {:ok, entries, total: _total_count_of_entries} = Entries |> fetch_all
  ```

  You can create query chains to form more complex queries:

  ```
  import Contentful.Query
  alias Contentful.Delivery.Entries

  {:ok, entries, total: _total_count_of_entries} =
    Entries
    |> skip(2)
    |> limit(10)
    |> include(2)
    |> fetch_all
  ```

  Fetching indidvidual entities is straight forward:

  ```
  import Contentful.Query
  alias Contentful.Delivery.Assets

  my_asset_id = "my_asset_id"

  {:ok, assets, total: _total_count_of_assets} = Assets |> fetch_one(my_asset_id)
  ```

  All query resolvers also support chaning the `space_id`, `environment` and `access_token` at call
  time:

  ```
  import Contentful.Query
  alias Contentful.Delivery.Assets

  my_asset_id = "my_asset_id"
  {:ok, asset} =
    Assets
    |> fetch_one(my_asset_id)
  ```

  Note: If you want to pass the configuration at call time, you can pass these later as function
  parameters to the resolver call:

  ```
  import Contentful.Query
  alias Contentful.Delivery.Assets

  my_asset_id = "my_asset_id"
  my_space_id = "bmehzfuz4raf"
  my_environment = "staging"
  my_access_token = "not_a_real_token"

  {:ok, asset} =
    Assets
    |> fetch_one(my_asset_id, my_space_id, my_environment, my_access_token)

  # also works for fetch_all:
  {:ok, assets, _} =
    Assets
    |> fetch_all(my_space_id, my_environment, my_access_token)

  # and for stream:
  [ asset | _ ] =
    Assets
    |> stream(my_space_id, my_environment, my_access_token)
    |> Enum.to_list

  ```

  ## Spaces as an exception

  Unfortunately, `Contentful.Delivery.Spaces` do not support complete collection behaviour:

  ```
  # doesn't exist in the Delivery API:
  {:error, _, _} = Contentful.Delivery.Spaces |> fetch_all

  # however, you can still retrieve a single `Contentful.Space`:
  {:ok, space} = Contentful.Delivery.Spaces |> fetch_one # the configured space
  {:ok, my_space} = Contentful.Delivery.Spaces |> fetch_one("my_space_id") # a passed space

  ```

  ## Further reading

  * [Contentful Delivery API docs](https://www.contentful.com/developers/docs/references/content-delivery-api/) (CDA).
  """

  import Contentful.Misc, only: [fallback: 2]

  alias Contentful.Configuration

  @endpoint "cdn.contentful.com"
  @preview_endpoint "preview.contentful.com"
  @protocol "https"
  @separator "/"

  @doc """
  Constructs a new Tesla client for requests.

  Can be overridden with a custom client:

  ```
  # config/config.exs
  config :contentful, client: MyApp.CustomClient
  ```
  """
  @spec client :: Tesla.Client.t()
  def client do
    case Contentful.http_client do
      Tesla -> Tesla.client([])
      mod -> mod.client()
    end
  end

  @doc """
  Gets the json library for the Contentful Delivery API based
  on the config/config.exs.

  """
  @spec json_library :: module()
  def json_library do
    Contentful.json_library()
  end

  @doc """
  constructs the base url with protocol for the CDA

  ## Examples

      "https://cdn.contentful.com" = url()
  """
  @spec url() :: String.t()
  def url do
    "#{@protocol}://#{host_from_config()}"
  end

  @doc """
  constructs the base url with the space id that got configured in config.exs
  """
  @spec url(nil) :: String.t()
  def url(space) when is_nil(space) do
    case space_from_config() do
      nil ->
        url()

      space ->
        space |> url
    end
  end

  @doc """
  constructs the base url with the extension for a given space
  ## Examples

      "https://cdn.contentful.com/spaces/foo" = url("foo")
  """
  @spec url(String.t()) :: String.t()
  def url(space) do
    [url(), "spaces", space] |> Enum.join(@separator)
  end

  @doc """
  When explicilty given `nil`, will fetch the `environment` from the environments
  current config (see `config/config.exs`). Will fall back to `"master"` if no environment
  is set.

  ## Examples

    "https://cdn.contentful.com/spaces/foo/environments/master" = url("foo", nil)

    # With config set in config/config.exs
    config :contentful_delivery, environment: "staging"
    "https://cdn.contentful.com/spaces/foo/environments/staging" = url("foo", nil)
  """
  @spec url(String.t(), nil) :: String.t()
  def url(space, env) when is_nil(env) do
    [space |> url(), "environments", environment_from_config()]
    |> Enum.join(@separator)
  end

  @doc """
  constructs the base url for the delivery endpoint for a given space and environment

  ## Examples

      "https://cdn.contentful.com/spaces/foo/environments/bar" = url("foo", "bar")
  """
  def url(space, env) do
    [space |> url(), "environments", env] |> Enum.join(@separator)
  end

  @doc """
  Sends a request against the CDA. It's really just a wrapper around `Tesla.get/3`
  """
  @spec send_request({binary(), any()}) :: Tesla.Env.result()
  def send_request({url, headers}) do
    Tesla.get(client(), url, headers: headers)
  end

  @doc """
  Parses the response from the CDA and triggers a callback on success
  """
  @spec parse_response({:ok, Tesla.Env.t()}, fun()) ::
          {:ok, struct()}
          | {:ok, list(struct()), total: non_neg_integer()}
          | {:error, :rate_limit_exceeded, wait_for: integer()}
          | {:error, atom(), original_message: String.t()}
  def parse_response(
        {:ok, %Tesla.Env{status: code, body: body} = resp},
        callback
      ) do
    case code do
      200 ->
        body |> json_library().decode! |> callback.()

      401 ->
        body |> build_error(:unauthorized)

      404 ->
        body |> build_error(:not_found)

      _ ->
        resp |> build_error()
    end
  end

  @doc """
  catch_all for any errors during flight (connection loss, etc.)
  """
  @spec parse_response({:error, any()}, fun()) :: {:error, :unknown}
  def parse_response({:error, error}, _callback) do
    build_error()
  end

  @doc """
  Used to construct generic errors for calls against the CDA
  """
  @spec build_error(String.t(), atom()) ::
          {:error, atom(), original_message: String.t()}
  def build_error(response_body, status) do
    {:ok, %{"message" => message}} = response_body |> json_library().decode()
    {:error, status, original_message: message}
  end

  @doc """
    Used for the rate limit exceeded error, as it gives the user extra information on wait times
  """
  @spec build_error(Tesla.Env.t()) ::
          {:error, :rate_limit_exceeded, wait_for: integer()}
  def build_error(%Tesla.Env{
        status: 429,
        headers: [{"x-contentful-rate-limit-exceeded", seconds}, _]
      }) do
    {:error, :rate_limit_exceeded, wait_for: seconds}
  end

  @doc """
    Used to make a generic error, in case the API Response is not what is expected
  """
  @spec build_error() :: {:error, :unknown}
  def build_error do
    {:error, :unknown}
  end

  defp environment_from_config do
    Configuration.get(:environment) |> fallback("master")
  end

  defp space_from_config do
    Configuration.get(:space)
  end

  defp host_from_config do
    case Configuration.get(:endpoint) do
      nil -> @endpoint
      :preview -> @preview_endpoint
      value -> value
    end
  end
end
