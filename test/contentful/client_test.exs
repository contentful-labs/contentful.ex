defmodule Contentful.ClientTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  alias Contentful.Delivery.Entries
  alias Contentful.{ContentType, Entry, Space, SysData}

  use ExVCR.Mock, adapter: ExVCR.Adapter.Httpc

  import Contentful.Query

  @space_id "bmehzfuz4raf"
  @entry_id "5UeyMKZrmqMYyMMJvCP3Ls"
  @env "master"
  @access_token nil

  defmodule LoggingClient do
    # build dynamic client based on runtime arguments
    def client do
      middleware = [
        {Tesla.Middleware.Logger, debug: false}
      ]
      Tesla.client(middleware)
    end
  end

  setup do
    ExVCR.Config.filter_request_headers("authorization")

    # assign the LoggingClient to be the default Tesla client
    Application.put_env(:contentful, :http_client, LoggingClient)

    on_exit(fn ->
      # unassign the LoggingClient when testing is complete
      Application.delete_env(:contentful, :http_client)
    end)
  end

  describe "custom Tesla client" do
    test "will fetch one entry using assigned middleware" do
      use_cassette "single entry" do

        request = fn ->
          {:ok, %Entry{fields: _, sys: %SysData{id: @entry_id}}} =
            Entries |> fetch_one(@entry_id, @space_id, @env, @access_token)
        end

        assert capture_log(request) =~ "GET"
        assert capture_log(request) =~ "/spaces/#{@space_id}"
        assert capture_log(request) =~ "/entries/#{@entry_id}"
        assert capture_log(request) =~ "200"
      end
    end
  end
end
