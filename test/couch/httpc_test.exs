defmodule Couch.Test.HttpcTest do
  use ExUnit.Case

  test "json_body" do
    assert Couch.Httpc.json_body( %HTTPoison.Response{body: "{\"id\": 123}"} ) == {:ok, %{"id" => 123}}
    assert Couch.Httpc.json_body( %HTTPoison.Response{body: "invalid"} ) == {:error, {:invalid, "i"}}
  end

  test "doc_url" do
    db = %Couch.DB{name: "database"}
    docid = "docid"
    assert Couch.Httpc.doc_url(db, docid) == "database/docid"
  end

  test "request" do
  end

  test "db_request" do
  end

  test "db_resp" do
  end

  test "make_headers" do
  end

end
