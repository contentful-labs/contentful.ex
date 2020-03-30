defmodule Contentful.Delivery.ContentTypesTest do
  use ExUnit.Case

  alias Contentful.{ContentType, MetaData, Space}
  alias Contentful.Delivery.ContentTypes

  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @space_id "bmehzfuz4raf"
  @access_token nil
  @env "master"

  setup_all do
    HTTPoison.start()
  end

  setup do
    ExVCR.Config.filter_request_headers("authorization")
    :ok
  end

  describe ".fetch_all" do
    test "fetches a set of content types to a space" do
      use_cassette "multiple_content_types" do
        space = %Space{meta_data: %MetaData{id: @space_id}}

        {:ok, [%ContentType{description: "A product model"} | _], total: 1} =
          ContentTypes.fetch_all([], space, @env, @access_token)
      end
    end

    test "will fetch all published entries for a space, respecting the limit parameter" do
      use_cassette "multiple content types - limit filter" do
        {:ok, [%ContentType{description: "A category"}], total: 2} =
          ContentTypes.fetch_all([limit: 1], @space_id)
      end
    end

    test "will fetch all content types for a space, respecting the skip param" do
      use_cassette "multiple content types - skip filter" do
        {:ok, [%ContentType{description: "A product model"}], total: 2} =
          ContentTypes.fetch_all([skip: 1], @space_id)
      end
    end

    test "will fetch fetch all published entries for a space, respecting both the skip and the limit param" do
      use_cassette "multiple content types - all filters" do
        {:ok, [%ContentType{description: "A product model"}], total: 2} =
          ContentTypes.fetch_all([skip: 1, limit: 1], @space_id)
      end
    end
  end

  describe ".fetch_one" do
    test "fetches a single content type by id for a given space" do
      use_cassette "single_content_type" do
        {:ok, %ContentType{description: "A product model"}} =
          ContentTypes.fetch_one("product", @space_id, @env, @access_token)
      end
    end
  end
end
