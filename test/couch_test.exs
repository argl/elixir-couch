defmodule Couch.Test do
  use ExUnit.Case
  doctest Couch

  setup do
    url = Application.get_env(:couch, :url)
    dbname = "test_database"
    repl_dbname = "test_replication"
    create_dbname = "test_create"
    {:ok, [url: url, dbname: dbname, repl_dbname: repl_dbname, create_dbname: create_dbname]}
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
    assert resp.couchdb == "Welcome"
    assert resp.version
  end

  test "get_uuid", %{url: url} do
    connection = Couch.server_connection url
    uuids = Couch.get_uuid(connection, 10)
    assert length(uuids) == 10
    assert String.length(hd(uuids)) == 32
  end

  test "replicate", %{url: url, dbname: dbname, repl_dbname: repl_dbname} do
    connection = Couch.server_connection url
    repl_obj = %{source: dbname, target: repl_dbname, create_target: true}
    {:ok, resp} = Couch.replicate(connection, repl_obj)
    assert resp.ok == true

    repl_obj = %{source: "non existing db", target: repl_dbname, create_target: true}
    assert {:error, _} = Couch.replicate(connection, repl_obj)
  end

  test "replicate shortcuts", %{url: url, dbname: dbname, repl_dbname: repl_dbname} do
    connection = Couch.server_connection url
    db1 = %Couch.DB{server: connection, name: dbname}
    db2 = %Couch.DB{server: connection, name: repl_dbname}
    {:ok, resp} = Couch.replicate(connection, dbname, repl_dbname, %{create_target: true})
    assert resp.ok == true
    {:ok, resp} = Couch.replicate(connection, db1, repl_dbname, %{create_target: true})
    assert resp.ok == true
    {:ok, resp} = Couch.replicate(connection, dbname, db2, %{create_target: true})
    assert resp.ok == true
    {:ok, resp} = Couch.replicate(connection, db1, db2, %{create_target: true})
    assert resp.ok == true
  end

  test "all_dbs", %{url: url} do
    connection = Couch.server_connection url
    result = Couch.all_dbs(connection)
    assert {:ok, resp} = result
    assert is_list(resp) == true
    assert length(resp) > 1
    assert Enum.member?(resp, "_users")
  end

  test "db_exists", %{url: url, dbname: dbname} do
    connection = Couch.server_connection url
    result = Couch.db_exists(connection, dbname)
    assert result
    result = Couch.db_exists(connection, "non existing db")
    assert !result
  end

  test "create_db, delete_db", %{url: url, create_dbname: create_dbname} do
    connection = Couch.server_connection url

    if Couch.db_exists(connection, create_dbname) do
      # this is not pretty. delete_db is not tested at this point
      # testing against a mock would prevent this situation. oh my.
      Couch.delete_db(connection, create_dbname)
    end

    {:ok, db} = Couch.create_db(connection, create_dbname)
    assert db.server == connection
    assert db.name == create_dbname

    {:ok, response} = Couch.delete_db(connection, create_dbname)
    assert response.ok
    assert !Couch.db_exists(connection, create_dbname)
  end

  test "open_db", %{url: url, create_dbname: create_dbname} do
    connection = Couch.server_connection url
    if Couch.db_exists(connection, create_dbname) do
      Couch.delete_db(connection, create_dbname)
    end
    {:ok, db} = Couch.open_db(connection, create_dbname)
    assert db.server == connection
    assert db.name == create_dbname
  end

  test "open_or_create_db", %{url: url, create_dbname: create_dbname} do
    connection = Couch.server_connection url
    if Couch.db_exists(connection, create_dbname) do
      Couch.delete_db(connection, create_dbname)
    end
    {:ok, db} = Couch.open_or_create_db(connection, create_dbname)
    assert db.server == connection
    assert db.name == create_dbname
    assert Couch.db_exists(connection, create_dbname)
    Couch.delete_db(connection, create_dbname)
  end

  test "db_info", %{url: url, dbname: dbname} do
    connection = Couch.server_connection url
    {:ok, db} = Couch.open_db(connection, dbname)
    {:ok, infos} = Couch.db_info(db)
    assert infos.db_name == dbname

    {:ok, db} = Couch.open_db(connection, "non-exisiting-db")
    assert {:error, :db_not_found} = Couch.db_info(db)
  end

  test "doc_exist", %{url: url} do
    connection = Couch.server_connection url
    db = %Couch.DB{name: "_replicator", server: connection}
    assert Couch.doc_exists(db, "_design/_replicator")
    assert !Couch.doc_exists(db, "_design/nothing_here")
  end

  test "open_doc", %{url: url} do
    connection = Couch.server_connection url
    db = %Couch.DB{name: "_replicator", server: connection}
    {:ok, doc} = Couch.open_doc(db, "_design/_replicator")
    assert doc._id == "_design/_replicator"
    assert doc._rev
    {:error, :not_found} = Couch.open_doc(db, "_design/non-existing")
  end

  test "basic single save_doc, delete_doc", %{url: url, dbname: dbname} do
    connection = Couch.server_connection url
    db = %Couch.DB{name: dbname, server: connection}
    doc = %{_id: "test-document", attr: "test"}
    if Couch.doc_exists(db, doc._id) do
      {:ok, doc_to_delete} = Couch.open_doc(db, doc._id)      
      {:ok, _response} = Couch.delete_doc(db, doc_to_delete)
    end
    result = Couch.save_doc(db, doc)
    assert {:ok, saved} = result
    assert saved.id == doc._id
    assert saved.rev

    result = Couch.save_doc(db, doc)
    assert {:error, :conflict} = result
    result = Couch.delete_doc(db, doc)
    assert {:ok, _deleted} = result
  end

  test "bulk save_docs, delete_docs", %{url: url, dbname: dbname} do
    connection = Couch.server_connection url
    db = %Couch.DB{name: dbname, server: connection}
    docs = [%{_id: "test-document1", attr: "test"}, %{_id: "test-document2", attr: "test"}]
    Enum.each(docs, fn(doc) -> 
      if Couch.doc_exists(db, doc._id) do
        {:ok, doc_to_delete} = Couch.open_doc(db, doc._id)
        {:ok, _response} = Couch.delete_doc(db, doc_to_delete)
      end
    end)
    result = Couch.save_docs(db, docs)
    assert {:ok, _saved} = result
    # result = Couch.save_doc(db, doc)
    # assert {:error, :conflict} = result
    result = Couch.delete_docs(db, docs)
    assert {:ok, _deleted} = result
  end

  test "copy_doc", %{url: url, dbname: dbname} do
    connection = Couch.server_connection url
    db = %Couch.DB{name: dbname, server: connection}
    doc = %{_id: "test-document", attr: "test"}
    destination_doc_id = "new-doc-id"
    if Couch.doc_exists(db, doc._id) do
      {:ok, doc_to_delete} = Couch.open_doc(db, doc._id)      
      {:ok, _response} = Couch.delete_doc(db, doc_to_delete)
    end
    if Couch.doc_exists(db, "new-doc-id") do
      {:ok, doc_to_delete} = Couch.open_doc(db, destination_doc_id)      
      {:ok, _response} = Couch.delete_doc(db, doc_to_delete)
    end
    {:ok, result} = Couch.save_doc(db, doc)
    doc = Map.merge doc, %{_rev: result.rev}

    result = Couch.copy_doc(db, doc._id, destination_doc_id)
    assert {:ok, new_doc_id, new_ref} = result
    {:ok, new_doc} = Couch.open_doc(db, destination_doc_id)
    assert new_doc._id == destination_doc_id
    assert new_doc._id== new_doc_id
    assert new_doc,_rev = new_ref
    {:ok, _response} = Couch.delete_doc(db, doc)
    {:ok, _response} = Couch.delete_doc(db, new_doc)
  end

  # test "get streaming douments" , %{url: url, dbname: dbname} do
  #   # streaming documents? for tests see couchbeam.erl, line 1229
  # end

  # test "save_doc, delete_doc", %{url: url, dbname: dbname} do
  # end




end
