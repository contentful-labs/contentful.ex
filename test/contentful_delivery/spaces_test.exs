defmodule Contentful.Delivery.SpacesTest do
  use ExUnit.Case

  alias Contentful.Delivery.Spaces
  alias Contentful.Space

  import Contentful.Query

  use ExVCR.Mock, adapter: ExVCR.Adapter.Httpc

  @space_id "bmehzfuz4raf"
  @access_token "a token"

  setup do
    ExVCR.Config.filter_request_headers("authorization")
    :ok
  end

  describe "fetch_one/3" do
    test "will fetch one space" do
      use_cassette "single space" do
        {:ok, %Space{name: "Products", sys: %{id: @space_id}}} =
          Spaces |> fetch_one(@space_id, @access_token)
      end
    end

    test "will give an error upon requesting a non existing space" do
      use_cassette "non existing space" do
        {:error, :not_found, original_message: _} = Spaces |> fetch_one("foobarfoo", @access_token)
      end
    end

    test "will give an error indicating wrong credentials" do
      use_cassette "non accessible space" do
        {:error, :unauthorized, original_message: _} = Spaces |> fetch_one(@space_id, "fooo")
      end
    end
  end
end
