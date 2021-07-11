defmodule ContentfulTest do
  use ExUnit.Case
  doctest Contentful

  test "json_library checks the lib in use" do
    assert Contentful.json_library() == Jason
  end

  test "http_client checks the lib in use" do
    assert Contentful.http_client() == Tesla
  end
end
