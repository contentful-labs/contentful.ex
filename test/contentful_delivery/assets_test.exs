defmodule Contentful.Delivery.AssetsTest do
  use ExUnit.Case
  alias Contentful.{Asset, SysData}
  alias Contentful.Delivery.Assets

  use ExVCR.Mock, adapter: ExVCR.Adapter.Httpc

  import Contentful.Query

  @space_id "bmehzfuz4raf"
  @env "master"
  @asset_id "577fpmbIfYD71VCjCpYA84"
  @access_token nil

  setup do
    ExVCR.Config.filter_request_headers("authorization")
    :ok
  end

  describe ".fetch_one" do
    test "fetches a single asset by it's id from a space" do
      use_cassette "single asset" do
        {:ok, %Asset{sys: %{id: @asset_id}}} = Assets |> fetch_one(@asset_id, @space_id)
      end
    end

    test "contains the meta information in sys" do
      use_cassette "single asset" do
        {:ok, %Asset{sys: %SysData{id: @asset_id, updated_at: _, created_at: _, locale: _} = sys}} =
          Assets |> fetch_one(@asset_id, @space_id)

        assert sys.created_at
        assert sys.updated_at
        assert sys.locale
      end
    end
  end

  describe ".fetch_all" do
    test "fetches all assets for a given space" do
      use_cassette "multiple assets" do
        {:ok,
         [
           %Asset{fields: %{file: %{content_type: "application/pdf"}}},
           %Asset{fields: %{file: %{content_type: "image/png"}}}
         ], total: 2} = Assets |> fetch_all(@space_id)
      end
    end

    test "will fetch all published assets for a space, respecting the limit parameter" do
      use_cassette "multiple assets, limit filter" do
        {:ok, [%Asset{fields: %{title: "bafoo"}}], total: 2} =
          Assets |> limit(1) |> fetch_all(@space_id)
      end
    end

    test "will fetch all published assets for a space, respecting the skip param" do
      use_cassette "multiple assets, skip filter" do
        {:ok, [%Asset{fields: %{title: "Foobar"}}], total: 2} =
          Assets |> skip(1) |> fetch_all(@space_id)
      end
    end

    test "will fetch fetch all published assets for a space, respecting both the skip and the limit param" do
      use_cassette "multiple assets, all filters" do
        {:ok, [%Asset{fields: %{title: "Foobar"}}], total: 2} =
          Assets |> limit(1) |> skip(1) |> fetch_all(@space_id)
      end
    end

    test "will fetch all published assets, filtered by a name" do
      use_cassette "multiple assets, filtered by name" do
        {:ok, [%Asset{fields: %{title: "bafoo"}}], total: 1} =
          Assets
          |> by(title: "bafoo")
          |> fetch_all(@space_id, @env, @access_token)
      end
    end

    test "will fetch all published assets, filtered by a name, negated" do
      use_cassette "multiple assets, filtered by name, negated" do
        {:ok, [%Asset{fields: %{title: nil}}], total: 1} =
          Assets
          |> by(title: [ne: "bafoo"])
          |> fetch_all(@space_id, @env, @access_token)
      end
    end
  end

  describe ".stream" do
    test "streams asset calls" do
      use_cassette "multiple assets, limit filter, streamed" do
        [%Asset{}, %Asset{}] = Assets |> limit(1) |> stream(@space_id) |> Enum.to_list()
      end
    end
  end
end
