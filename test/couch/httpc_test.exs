defmodule Couch.Test.HttpcTest do
  use ExUnit.Case

  test "json_body" do
    assert Couch.Httpc.json_body( %HTTPoison.Response{body: "{\"id\": 123}"} ) == {:ok, %{"id" => 123}}
    assert Couch.Httpc.json_body( %HTTPoison.Response{body: "invalid"} ) == {:error, {:invalid, "i"}}
  end

end
