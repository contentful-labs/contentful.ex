defmodule Contentful.Delivery.LocalesTest do
  use ExUnit.Case

  alias Contentful.Delivery.Locales
  alias Contentful.Locale

  use ExVCR.Mock, adapter: ExVCR.Adapter.Httpc

  import Contentful.Query

  @space_id "bmehzfuz4raf"
  @env "master"
  @access_token nil

  setup do
    ExVCR.Config.filter_request_headers("authorization")
    :ok
  end

  describe "fetch_all/4" do
    test "will fetch all locales for a given space" do
      use_cassette "locales" do
        {:ok,
         [
           %Locale{code: "en-US", default: true},
           %Locale{code: "de", default: false}
         ], total: 2} = Locales |> fetch_all(@space_id, @env, @access_token)
      end
    end
  end
end
