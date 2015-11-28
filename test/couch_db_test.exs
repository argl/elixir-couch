# Copyright (c) 2015 Andi Pieper

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

defmodule Couch.Test.BasicTest do
  use ExUnit.Case
  doctest Couch

  alias Couch.Client
  alias Couch.TestHelpers

  setup do
    ret = TestHelpers.clean_dbs []
    ret = TestHelpers.create_db ret
    {:ok, ret}
  end

  test "server_connection via url", %{url: url} do
    assert Client.server_connection == %Client.Server{url: "http://127.0.0.1:5984/"}
    assert Client.server_connection("http://127.0.0.1:5984") == %Client.Server{url: "http://127.0.0.1:5984/"}
    assert Client.server_connection("http://127.0.0.1:5984", [bla: 123]) == %Client.Server{url: "http://127.0.0.1:5984/", options: [bla: 123]}
    assert Client.server_connection url
  end

  test "server_connection via host, port etc" do
    assert Client.server_connection("localhost", 5984) == %Client.Server{url: "http://localhost:5984/"}
    assert Client.server_connection("localhost", 443) == %Client.Server{url: "https://localhost:443/"}
    assert Client.server_connection("localhost", 4430, "", [is_ssl: true]) == %Client.Server{url: "https://localhost:4430/", options: [is_ssl: true]}
    assert Client.server_connection("localhost", 4430, "prefix", [is_ssl: true]) == %Client.Server{url: "https://localhost:4430/prefix/", options: [is_ssl: true]}
  end

  test "server_info", %{url: url} do
    connection = Client.server_connection url
    {:ok, resp} = Client.server_info(connection)
    assert resp.couchdb == "Welcome"
    assert resp.version
  end

  test "get_uuid", %{url: url} do
    connection = Client.server_connection url
    uuids = Client.get_uuid(connection, 10)
    assert length(uuids) == 10
    assert String.length(hd(uuids)) == 32
  end

  test "replicate", %{url: url, dbname: dbname, repl_dbname: repl_dbname} do
    connection = Client.server_connection url
    repl_obj = %{source: dbname, target: repl_dbname, create_target: true}
    {:ok, resp} = Client.replicate(connection, repl_obj)
    assert resp.ok == true

    repl_obj = %{source: "non existing db", target: repl_dbname, create_target: true}
    assert {:error, _} = Client.replicate(connection, repl_obj)
  end

  test "replicate shortcuts", %{url: url, dbname: dbname, repl_dbname: repl_dbname} do
    connection = Client.server_connection url
    db1 = %Client.DB{server: connection, name: dbname}
    db2 = %Client.DB{server: connection, name: repl_dbname}
    {:ok, resp} = Client.replicate(connection, dbname, repl_dbname, %{create_target: true})
    assert resp.ok == true
    {:ok, resp} = Client.replicate(connection, db1, repl_dbname, %{create_target: true})
    assert resp.ok == true
    {:ok, resp} = Client.replicate(connection, dbname, db2, %{create_target: true})
    assert resp.ok == true
    {:ok, resp} = Client.replicate(connection, db1, db2, %{create_target: true})
    assert resp.ok == true
  end

  test "all_dbs", %{url: url} do
    connection = Client.server_connection url
    result = Client.all_dbs(connection)
    assert {:ok, resp} = result
    assert is_list(resp) == true
    assert length(resp) > 1
    assert Enum.member?(resp, "_users")
  end

  test "db_exists", %{url: url, dbname: dbname} do
    connection = Client.server_connection url
    result = Client.db_exists(connection, dbname)
    assert result
    result = Client.db_exists(connection, "non existing db")
    assert !result
  end

  test "create_db, delete_db", %{url: url, create_dbname: create_dbname} do
    connection = Client.server_connection url

    assert {:ok, db} = Client.create_db(connection, create_dbname)
    assert db.server == connection
    assert db.name == create_dbname
    assert {:error, :db_exists} = Client.create_db(connection, create_dbname)
 
    assert {:ok, response} = Client.delete_db(connection, create_dbname)
    assert response.ok
    assert {:error, :not_found} = Client.delete_db(connection, create_dbname)
    assert !Client.db_exists(connection, create_dbname)
  end

  test "open_db", %{url: url, create_dbname: create_dbname} do
    connection = Client.server_connection url
    {:ok, db} = Client.open_db(connection, create_dbname)
    assert db.server == connection
    assert db.name == create_dbname
  end

  test "open_or_create_db", %{url: url, create_dbname: create_dbname} do
    connection = Client.server_connection url
    {:ok, db} = Client.open_or_create_db(connection, create_dbname)
    assert db.server == connection
    assert db.name == create_dbname
    assert Client.db_exists(connection, create_dbname)
  end

  test "db_info", %{url: url, dbname: dbname} do
    connection = Client.server_connection url
    {:ok, db} = Client.open_db(connection, dbname)
    {:ok, infos} = Client.db_info(db)
    assert infos.db_name == dbname

    {:ok, db} = Client.open_db(connection, "non-exisiting-db")
    assert {:error, :db_not_found} = Client.db_info(db)
  end

  test "doc_exist", %{url: url} do
    connection = Client.server_connection url
    db = %Client.DB{name: "_replicator", server: connection}
    assert Client.doc_exists(db, "_design/_replicator")
    assert !Client.doc_exists(db, "_design/nothing_here")
  end

  test "open_doc", %{url: url} do
    connection = Client.server_connection url
    db = %Client.DB{name: "_replicator", server: connection}
    {:ok, doc} = Client.open_doc(db, "_design/_replicator")
    assert doc._id == "_design/_replicator"
    assert doc._rev
    {:error, :not_found} = Client.open_doc(db, "_design/non-existing")
  end

  test "save_doc, delete_doc", %{url: url, dbname: dbname} do
    connection = Client.server_connection url
    db = %Client.DB{name: dbname, server: connection}
    doc = %{_id: "test-document", attr: "test"}
    result = Client.save_doc(db, doc)
    assert {:ok, saved} = result
    assert saved.id == doc._id
    assert saved.rev

    result = Client.save_doc(db, doc)
    assert {:error, :conflict} = result
    result = Client.delete_doc(db, doc)
    assert {:ok, _deleted} = result

    doc = %{_id: "~!@#$%^&*()_+-=[]{}|;':,./<> ?"}
    {:ok, _} = Client.save_doc(db, doc)
    {:ok, doc_read} = Client.open_doc(db, "~!@#$%^&*()_+-=[]{}|;':,./<> ?")
    assert "~!@#$%^&*()_+-=[]{}|;':,./<> ?" == doc_read._id

  end

  test "bulk save_docs, delete_docs", %{url: url, dbname: dbname} do
    connection = Client.server_connection url
    db = %Client.DB{name: dbname, server: connection}
    docs = [%{_id: "test-document1", attr: "test"}, %{_id: "test-document2", attr: "test"}]
    result = Client.save_docs(db, docs)
    assert {:ok, _saved} = result
    result = Client.save_doc(db, hd(docs))
    assert {:error, :conflict} = result

    {:ok, doc1} = Client.open_doc(db, "test-document1")
    {:ok, doc2} = Client.open_doc(db, "test-document2")
    assert {:ok, _deleted} = Client.delete_docs(db, [doc1, doc2])
    assert {:error, :not_found} = Client.open_doc(db, "test-document1")
  end

  test "copy_doc", %{url: url, dbname: dbname} do
    connection = Client.server_connection url
    db = %Client.DB{name: dbname, server: connection}
    doc = %{_id: "test-document", attr: "test"}
    destination_doc_id = "new-doc-id"
    {:ok, result} = Client.save_doc(db, doc)
    doc = Map.merge doc, %{_rev: result.rev}

    result = Client.copy_doc(db, doc._id, destination_doc_id)
    assert {:ok, new_doc_id, new_ref} = result
    {:ok, new_doc} = Client.open_doc(db, destination_doc_id)
    assert new_doc._id == destination_doc_id
    assert new_doc._id== new_doc_id
    assert new_doc,_rev = new_ref
  end

  test "lookup_doc_rev", %{url: url, dbname: dbname} do
    connection = Client.server_connection url
    db = %Client.DB{name: dbname, server: connection}
    doc = %{_id: "test-document", attr: "test"}
    {:ok, result} = Client.save_doc(db, doc)
    doc = Map.merge doc, %{_rev: result.rev}

    looked_up_rev = Client.lookup_doc_rev(db, doc._id)
    assert looked_up_rev == doc._rev

    result = Client.lookup_doc_rev(db, "non-existing")
    assert {:error, _} = result
  end

  test "put_attachment, fetch_attachment", %{url: url, dbname: dbname} do
    connection = Client.server_connection url
    db = %Client.DB{name: dbname, server: connection}

    doc = %{_id: "test"}
    {:ok, res} = Client.save_doc(db, doc)
    rev = res.rev
    {:ok, res} = Client.put_attachment(db, "test", "test", "test", [bla: 123, rev: rev])
    rev2 = res.rev
    assert rev != rev2

    result = Client.fetch_attachment(db, "test", "test")
    {:ok, attachment} = result
    assert "test" == attachment
    {:ok, doc} = Client.open_doc(db, "test")
    {:ok, resp} = Client.delete_attachment(db, doc, "test")
    assert doc._rev != resp.rev
    assert match? {:error, :not_found}, Client.fetch_attachment(db, "test", "test") 
    {:error, :conflict} = Client.delete_attachment(db, doc, "test")
    doc = %{doc | _rev: resp.rev}
    {:ok, _resp} = Client.delete_attachment(db, doc, "test")
  end

  test "compact", %{url: url, dbname: dbname} do
    connection = Client.server_connection url
    db = %Client.DB{name: dbname, server: connection}
    assert match? :ok, Client.compact(db)
  end

  # test "inline attachments", %{url: url, dbname: dbname} do
    # TODO: inline attachments not implemented (yet)
    # Doc3 = {[{<<"_id">>, <<"test2">>}]},
    # Doc4 = couchbeam_attachments:add_inline(Doc3, "test", "test.txt"),
    # Doc5 = couchbeam_attachments:add_inline(Doc4, "test2", "test2.txt"),
    # {ok, _} = couchbeam:save_doc(Db, Doc5),
    # {ok, Attachment1} = couchbeam:fetch_attachment(Db, "test2", "test.txt"),
    # {ok, Attachment2} = couchbeam:fetch_attachment(Db, "test2", "test2.txt"),
    # ?assertEqual( <<"test">>, Attachment1),
    # ?assertEqual( <<"test2">>, Attachment2),
    # {ok, Doc6} = couchbeam:open_doc(Db, "test2"),
    # Doc7 = couchbeam_attachments:delete_inline(Doc6, "test2.txt"),
    # {ok, _} = couchbeam:save_doc(Db, Doc7),
    # ?assertEqual({error, not_found}, couchbeam:fetch_attachment(Db, "test2", "test2.txt")),
    # {ok, Attachment4} = couchbeam:fetch_attachment(Db, "test2", "test.txt"),
    # ?assertEqual( <<"test">>, Attachment4),
    # {ok, Doc8} = couchbeam:save_doc(Db, {[]}),
  # end

  test "all_docs", %{url: url, dbname: dbname} do
    connection = Client.server_connection url
    db = %Client.DB{name: dbname, server: connection}
    {:ok, resp} = Client.all_docs(db)
    assert resp.total_rows == 0
    assert resp.rows == []
    assert resp.offset == 0

    doc = %{_id: "test-document", attr: "test"}
    {:ok, resp} = Client.save_doc(db, doc)
    doc = Map.merge doc, %{_rev: resp.rev}

    {:ok, resp} = Client.all_docs(db)
    assert resp.total_rows == 1
    assert length(resp.rows) == 1
    assert resp.offset == 0
    assert hd(resp.rows).id == doc._id
    assert hd(resp.rows).value.rev == doc._rev

    {:ok, resp} = Client.all_docs(db, [skip: 1])
    assert resp.total_rows == 1
    assert length(resp.rows) == 0
    assert resp.offset == 1
  end

  test "fetch_view", %{url: url, dbname: dbname} do
    connection = Client.server_connection url
    db = %Client.DB{name: dbname, server: connection}
    design_doc = %{
      _id: "_design/test", 
      language: "javascript",
      views: %{
        test_view_1: %{
          map: "function(doc) { if (doc.type == \"test\") { emit(doc._id, doc); } }"
        },
        test_view_2: %{
          map: "function(doc) { if (doc.type == \"test2\") { emit(doc._id, doc); } }"
        }
      }
    }
    {:ok, _} = Client.save_doc(db, design_doc)

    docs = [
      %{_id: "test-document", type: "test"},
      %{_id: "test-document2", type: "test"},
      %{_id: "test-document3", type: "test2"}
    ]
    {:ok, _} = Client.save_docs(db, docs)

    {:ok, resp} = Client.fetch_view(db, "test", "test_view_1")
    assert resp.total_rows == 2
    assert length(resp.rows) == 2
    assert hd(resp.rows).id == hd(docs)._id

    {:ok, resp} = Client.fetch_view(db, "test", "test_view_2")
    assert resp.total_rows == 1
    assert length(resp.rows) == 1
    assert hd(resp.rows).id == hd(Enum.reverse(docs))._id

  end

end
