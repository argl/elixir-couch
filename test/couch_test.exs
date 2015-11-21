defmodule Couch.Test do
  use ExUnit.Case
  doctest Couch

  setup do
    url = Application.get_env(:couch, :url)
    {:ok, [url: url]}
  end

  test "server_connection via url", %{url: url} do
    assert Couch.server_connection == %Couch.Server{url: "http://127.0.0.1:5984/"}
    assert Couch.server_connection("http://127.0.0.1:5984") == %Couch.Server{url: "http://127.0.0.1:5984/"}
    assert Couch.server_connection("http://127.0.0.1:5984", [bla: 123]) == %Couch.Server{url: "http://127.0.0.1:5984/", options: [bla: 123]}
    assert Couch.server_connection url
  end

  test "server_connection via host, port etc" do
    assert Couch.server_connection("localhost", 5984) == %Couch.Server{url: "http://localhost:5984/"}
    assert Couch.server_connection("localhost", 443) == %Couch.Server{url: "https://localhost:443/"}
    assert Couch.server_connection("localhost", 4430, "", [is_ssl: true]) == %Couch.Server{url: "https://localhost:4430/", options: [is_ssl: true]}
    assert Couch.server_connection("localhost", 4430, "prefix", [is_ssl: true]) == %Couch.Server{url: "https://localhost:4430/prefix/", options: [is_ssl: true]}
  end

  test "server_info", %{url: url} do
    connection = Couch.server_connection url
    {:ok, resp} = Couch.server_info(connection)
    assert Map.get(resp, "couchdb") == "Welcome"
    assert Map.get(resp, "version") 
  end

  test "get_uuid", %{url: url} do
    connection = Couch.server_connection url
    uuids = Couch.get_uuid(connection, 10)
    assert length(uuids) == 10
    assert String.length(hd(uuids)) == 32
  end

  test "replicate", %{url: url} do
    connection = Couch.server_connection url
    repl_obj = %{source: "test_database", target: "test_replication", create_target: true}
    {:ok, resp} = Couch.replicate(connection, repl_obj)
    assert Map.get(resp, "ok") == true
  end

end
