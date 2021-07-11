defmodule Contentful.Delivery.EntriesTest do
  use ExUnit.Case

  alias Contentful.Delivery.Entries
  alias Contentful.{ContentType, Entry, Space, SysData}

  use ExVCR.Mock, adapter: ExVCR.Adapter.Httpc

  import Contentful.Query

  @space_id "bmehzfuz4raf"
  @entry_id "5UeyMKZrmqMYyMMJvCP3Ls"
  @env "master"
  @access_token nil

  setup do
    ExVCR.Config.filter_request_headers("authorization")
    :ok
  end

  describe ".fetch_one" do
    test "will fetch one entry from the given space" do
      use_cassette "single entry" do
        {:ok, %Entry{fields: _, sys: %SysData{id: @entry_id}}} =
          Entries |> fetch_one(@entry_id, @space_id, @env, @access_token)
      end
    end

    test "provides meta information" do
      use_cassette "single entry" do
        {:ok,
         %Entry{
           sys:
             %SysData{
               updated_at: _,
               created_at: _,
               locale: _,
               content_type: content_type_id
             } = sys
         }} = Entries |> fetch_one(@entry_id, @space_id, @env, @access_token)

        assert sys.updated_at
        assert sys.created_at
        assert sys.locale

        assert content_type_id
      end
    end
  end

  describe ".fetch_all" do
    test "will fetch all published entries for a given space" do
      use_cassette "multiple entries" do
        {:ok, [%Entry{}, %Entry{}], total: 2} =
          Entries |> fetch_all(%Space{sys: %SysData{id: @space_id}})
      end
    end

    test "will fetch all published entries for a space, respecting the limit parameter" do
      use_cassette "multiple entries, limit filter" do
        {:ok, [%Entry{fields: %{"name" => "Purple Thunder"}}], total: 2} =
          Entries |> limit(1) |> fetch_all(%Space{sys: %SysData{id: @space_id}})
      end
    end

    test "will fetch all published entries for a space, respecting the skip param" do
      use_cassette "multiple entries, skip filter" do
        {:ok, [%Entry{fields: %{"name" => "Blue steel"}}], total: 2} =
          Entries
          |> skip(1)
          |> fetch_all(
            %Space{sys: %SysData{id: @space_id}},
            @env
          )
      end
    end

    test "will fetch all published entries for a space, respecting both the skip and the limit param" do
      use_cassette "multiple entries, all filters" do
        {:ok, [%Entry{fields: %{"name" => "Blue steel"}}], total: 2} =
          Entries
          |> skip(1)
          |> limit(1)
          |> fetch_all(
            @space_id,
            @env,
            @access_token
          )
      end
    end

    test "will fetch all published entries by spaces, filtered by content_type" do
      use_cassette "multiple entries, filtered by content_type" do
        {:ok,
         [
           %Entry{
             sys: %SysData{id: "7qCGg4LadgJUcx5cr35Ou9", content_type: %ContentType{id: "category"}}
           },
           %Entry{
             sys: %SysData{id: "4RPjazUzQMqemyNlcD3b9i", content_type: %ContentType{id: "category"}}
           }
         ],
         total: 2} =
          Entries
          |> content_type("category")
          |> fetch_all(@space_id, @env, @access_token)
      end
    end

    test "will support select as a way of selecting sys.id" do
      use_cassette "single entry with select filters" do
        {:ok,
         [
           %Entry{
             sys: %SysData{id: "7qCGg4LadgJUcx5cr35Ou9", content_type: %ContentType{id: "category"}}
           }
         ],
         total: 1} =
          Entries
          |> content_type("category")
          |> by(id: "7qCGg4LadgJUcx5cr35Ou9")
          |> fetch_all(@space_id, @env, @access_token)
      end
    end

    test "will support negated filtering by field" do
      use_cassette "some entries not having an id" do
        {:ok,
         [
           %Entry{
             sys: %SysData{id: "4RPjazUzQMqemyNlcD3b9i", content_type: %ContentType{id: "category"}}
           }
         ],
         total: 1} =
          Entries
          |> content_type("category")
          |> by(id: [ne: "7qCGg4LadgJUcx5cr35Ou9"])
          |> fetch_all(@space_id, @env, @access_token)
      end
    end
  end
end
