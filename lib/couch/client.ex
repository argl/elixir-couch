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


defmodule Couch.Client do

  @timeout :infinity

  alias Couch.Util
  alias Couch.Httpc

  defmodule Server do
    defstruct url: nil,
              options: []
  end

  defmodule DB do
    defstruct server: nil,
              name: nil,
              options: []
  end


  # make server connection struct
  def server_connection do
    server_connection("http://127.0.0.1:5984", [])
  end
  def server_connection(url) do
    server_connection(url, [])
  end
  def server_connection(url, options) when is_list(options) do
    url = :hackney_url.make_url(url, [""], [])
    %Server{url: url, options: options}
  end
  def server_connection(host, port) when is_integer(port) do
    server_connection(host, port, "", [])
  end
  def server_connection(host, port, prefix, options) when is_integer(port) and port == 443 do
    base_url = Enum.join [ "https://", host, ":", port ]
    url = :hackney_url.make_url(base_url, [prefix], [])
    server_connection url, options
  end
  def server_connection(host, port, prefix, options) do
    scheme = case Keyword.get(options, :is_ssl) do
      true -> "https"
      _ -> "http"
    end
    base_url = Enum.join [ scheme, "://", host, ":", port ]
    url = :hackney_url.make_url(base_url, [prefix], [])
    server_connection url, options
  end

  # get info from server
  def server_info(server) do
    case HTTPoison.get(server.url, [], server.options) do
      {:ok, resp} ->
        Httpc.json_body(resp, keys: :atoms)
      {:error, reason} ->
        {:error, reason}
      error ->
        error
    end
  end

  # Get one uuid from the server
  def get_uuid(server) do
    Couch.UUIDs.get_uuids(server, 1)
  end
  def get_uuid(server, count) do
    Couch.UUIDs.get_uuids(server, count)
  end


  # Handle replication. Pass an object containting all informations
  # It allows to pass for example an authentication info
  # rep_obj = %{source: "sourcedb", target: "targetdb", create_target: true}
  def replicate(server, rep_obj) do
    url = :hackney_url.make_url(server.url, ["_replicate"], [])
    headers = [{"Content-Type", "application/json"}]
    {:ok, json_obj} = Poison.encode(rep_obj)

    case HTTPoison.request(:post, url, json_obj, headers, server.options) do
      {:ok, resp} ->
        case resp.status_code do
          status_code when status_code == 200 or status_code ==201 -> 
            Httpc.json_body(resp, keys: :atoms)
          _ -> 
            {:error, {:bad_response, {resp.status_code, resp.headers, resp.body}}}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  def replicate(server, source, target) do
    replicate(server, source, target, %{})
  end
  def replicate(server, %DB{name: source}, target, options) do
    replicate(server, source, target, options)
  end
  def replicate(server, source, %DB{name: target}, options) do
    replicate(server, source, target, options)
  end
  def replicate(server, %DB{name: source}, %DB{name: target}, options) do
    replicate(server, source, target, options)
  end
  def replicate(server, source, target, options) do
    rep_obj = Map.merge options, %{ source: source, target: target }
    replicate(server, rep_obj)
  end


  # TODO
  # get_config
  # set_config
  # delete_config

  # all_dbs
  def all_dbs(%Server{url: server_url, options: opts}) do
    url = :hackney_url.make_url(server_url, "_all_dbs", [])
    case Httpc.db_request(:get, url, [], "", opts, [200]) do
      {:ok, resp} ->
        {:ok, all_dbs} = Httpc.json_body(resp, keys: :atoms)
        {:ok, all_dbs}
      {:error, reason} ->
        {:error, reason}
    end
  end
  # db_exists
  def db_exists(%Server{url: server_url, options: opts}, db_name) do
    url = :hackney_url.make_url(server_url, db_name, [])
    case Httpc.db_request(:head, url, [], "", opts, [200]) do
      {:ok, _resp} ->
        true
      _error ->
        false
    end
  end
  # create_db
  def create_db(%Server{url: server_url, options: opts} = server, db_name, options \\ [], params \\ []) do
    merged_options = Util.propmerge1(options, opts)
    url = :hackney_url.make_url(server_url, db_name, params)
    case Httpc.db_request(:put, url, [], "", merged_options, [201]) do
      {:ok, _resp} ->
        {:ok, %DB{server: server, name: db_name, options: merged_options}}
      {:error, :precondition_failed} ->
        {:error, :db_exists}
      error ->
        error
    end
  end
  # delete_db
  def delete_db(%DB{server: server, name: db_name}) do
    delete_db(server, db_name)
  end

  def delete_db(%Server{url: server_url, options: opts}, db_name) do
    url = :hackney_url.make_url(server_url, db_name, [])
    case Httpc.db_request(:delete, url, [], "", opts, [200]) do
      {:ok, resp} ->
        {:ok, response} = Httpc.json_body(resp, keys: :atoms)
        {:ok, response}
      error ->
        error
    end

  end

  # open_db
  def open_db(%Server{options: opts} = server, db_name, options \\ []) do
    merged_options = Util.propmerge1(options, opts)
    {:ok, %DB{server: server, name: db_name, options: merged_options}}
  end

  # open_or_create_db
  def open_or_create_db(%Server{url: server_url, options: opts} = server, db_name, options \\ [], params \\ []) do
    url = :hackney_url.make_url(server_url, db_name, [])
    merged_options = Util.propmerge1(options, opts)
    response = Httpc.db_request(:head, url, [], "", merged_options)
    case Httpc.db_resp(response, [200]) do
      {:ok, _resp} ->
        open_db(server, db_name, options);
      {:error, :not_found} ->
        create_db(server, db_name, options, params);
      error ->
        error
    end
  end
  
  # db_info
  def db_info(%DB{server: server, name: db_name, options: options}) do
    url = :hackney_url.make_url(server.url, db_name, [])
    case Httpc.db_request(:get, url, [], "", options, [200]) do
      {:ok, resp} ->
        {:ok, infos} = Httpc.json_body(resp, keys: :atoms)
        {:ok, infos}
      {:error, :not_found} ->
        {:error, :db_not_found}
      error ->
        error
    end
  end

  # doc_exist
  def doc_exists(%DB{server: server, options: options} = db, doc_id) do
    doc_id = Util.encode_docid(doc_id)
    url = :hackney_url.make_url(server.url, Httpc.doc_url(db, doc_id), [])
    case Httpc.db_request(:head, url, [], "", options, [200]) do
      {:ok, _resp} ->
        true
      _error ->
        false
    end
  end

  # open_doc
  def open_doc(%DB{server: server, options: options} = db, doc_id, params \\ []) do
    doc_id = Util.encode_docid(doc_id)

    {accept, params} = case Keyword.get(params, :accept) do
      nil -> {:any, params}
      a -> {a, Keyword.delete(params, :accept)}
    end

    headers = case {accept, List.keyfind(params, "attachments", 0)} do
      {:any, true} ->
        # %% only use the more efficient method when we get the
        # %% attachments so we don't use much bandwidth.
        [{"Accept", "multipart/related"}]
      {accept, _} when is_binary(accept)  ->
        # %% accepted content-type has been forced
        [{"Accept", accept}];
      _ ->
        []
    end

    url = :hackney_url.make_url(server.url, Httpc.doc_url(db, doc_id), params)
    case Httpc.db_request(:get, url, headers, "", options, [200, 201]) do
      {:ok, resp} ->
        case :hackney_headers.parse("content-type", resp.headers) do
          {"multipart", _, _} ->
            raise "multipart/related reponses not implemented (yet)"
            # %% we get a multipart request, start to parse it.
            initial_state = {resp, fn() -> Httpc.wait_mp_doc(resp, "") end }
            {:ok, {:multipart, initial_state}}
          _ ->
            {:ok, doc} = Httpc.json_body(resp, keys: :atoms)
            {:ok, doc}
        end
      error ->
        error
    end
  end

  # stream_doc
  # end_doc_stream

  # save_doc
  def save_doc(db, doc, options \\ []) do
    save_doc(db, doc, [], options)
  end
  def save_doc(%DB{server: server, options: opts} = db, doc, atts, options) do
    doc_id = case doc[:_id] do
      :nil ->
        [id] = get_uuid(server)
        id
      id ->
        Util.encode_docid(id)
    end
    url = :hackney_url.make_url(server.url, Httpc.doc_url(db, doc_id), options)
    case atts do
      [] ->
        {:ok, json_doc} = Poison.encode(doc)
        headers = [{"Content-Type", "application/json"}]
        case Httpc.db_request(:put, url, headers, json_doc, opts, [200, 201]) do
          {:ok, resp} ->
            {:ok, saved_doc} = Httpc.json_body(resp, keys: :atoms)
            {:ok, saved_doc}
          error ->
            error
        end
      _ ->
        raise "Saving multipart with attachments not implemented (yet)"
        #         Boundary = couchbeam_uuids:random(),

        #         %% for now couchdb can't received chunked multipart stream
        #         %% so we have to calculate the content-length. It also means
        #         %% that we need to know the size of each attachments. (Which
        #         %% should be expected).
        #         {CLen, JsonDoc, Doc2} = couchbeam_httpc:len_doc_to_mp_stream(Atts, Boundary, Doc),
        #         CType = <<"multipart/related; boundary=\"",
        #                   Boundary/binary, "\"" >>,

        #         Headers = [{<<"Content-Type">>, CType},
        #                    {<<"Content-Length">>, hackney_bstr:to_binary(CLen)}],

        #         case couchbeam_httpc:request(put, Url, Headers, stream,
        #                                      Opts) of
        #             {ok, Ref} ->
        #                 couchbeam_httpc:send_mp_doc(Atts, Ref, Boundary, JsonDoc, Doc2);
        #             Error ->
        #                 Error
        #         end
    end
  end

  # save_docs
  def save_docs(%DB{server: server, options: opts} = db, docs, options \\ []) do
    docs = Enum.map(docs, fn(doc) -> maybe_docid(server, doc) end)
    doc_options = for {k, v} <- options, (k == "all_or_nothing" or k == "new_edits") and is_boolean(v), do: %{k: v}
    options2 = for {k, v} <- options, k != "all_or_nothing" or k != "new_edits", do: {k, v}
    body = %{docs: docs}
    Enum.each(doc_options, fn(opt) -> Map.merge(body, opt) end)

    {:ok, body} = Poison.encode(body)
    # IO.inspect body
    url = :hackney_url.make_url(server.url, [db.name, "_bulk_docs"], options2)
    headers = [{"Content-Type", "application/json"}]
    case Httpc.db_request(:post, url, headers, body, opts, [201]) do
      {:ok, resp} ->
        {:ok, response} = Httpc.json_body(resp, keys: :atoms)
        {:ok, response}
      error ->
        error
    end
  end

  # delete_doc
  def delete_doc(db, doc, options \\ []) do
    delete_docs(db, [doc], options)
  end
  
  # delete_docs
  def delete_docs(db, docs, options \\ []) do
    empty = Util.get_value("empty_on_delete", options, false)
    {final_docs, final_options} = case empty do
      true ->
        docs = Enum.map(docs, fn(doc)-> %{_id: doc._id, _rev: doc._rev, _deleted: true} end)
        {docs, List.keydelete(options, "all_or_nothing", 0)}
      _ ->
        docs = Enum.map(docs, fn(doc)-> Map.put(doc, :_deleted, true) end)
        {docs, options}
    end
    save_docs(db, final_docs, final_options)
  end

  # copy_doc
  def copy_doc(%DB{server: server} = db, doc) do
    [doc_id] = get_uuid(server)
    copy_doc(db, doc, doc_id)
  end
  def copy_doc(db, doc, dest) when is_binary(dest) do
    destination = case open_doc(db, dest) do
      {:ok, dest_doc} ->
        rev = dest_doc["_rev"]
        %{_id: dest, _rev: rev}
      _ ->
        %{_id: dest, _rev: nil}
    end
    do_copy(db, doc, destination)
  end
  def copy_doc(db, doc, dest) do
    doc_id = dest._id
    rev = dest["_rev"]
    do_copy(db, doc, {doc_id, rev})
  end

  # do_copy
  def do_copy(db, doc, destination) when is_binary(destination) do
    do_copy(db, doc, %{_id: destination, _rev: nil})
  end
  def do_copy(db, doc_id, destination) when is_binary(doc_id) do
    do_copy(db, %{_id: doc_id, _rev: nil}, destination)
  end
  def do_copy(_db, %{_id: nil, _rev: _rev} = _doc, _destination) do
    {:error, :invalid_source}
  end
  def do_copy(%DB{server: server, options: opts}=db, %{_id: doc_id, _rev: doc_rev}, %{_id: dest_id, _rev: dest_rev}) do
    destination = case dest_rev do
      nil -> dest_id
      _ -> dest_id <> "?rev=" <> dest_rev
    end
    headers = [{"Destination", destination}]
    {headers, params} = case {doc_rev, dest_rev} do
      {nil, _} ->
        {headers, []}
      {_, nil} ->
        {[{"If-Match", doc_rev} | headers], []}
      {_, _} ->
        {headers, [{"rev", doc_rev}]}
    end
    url = :hackney_url.make_url(server.url, Httpc.doc_url(db, Util.encode_docid(doc_id)), params)
    case Httpc.db_request(:copy, url, headers, "", opts, [201]) do
      {:ok, resp} ->
        {:ok, response} = Httpc.json_body(resp, keys: :atoms)
        new_ref = response.rev
        new_doc_id = response.id
        {:ok, new_doc_id, new_ref}
      error ->
        error
    end
  end
  

  # lookup_doc_rev
  def lookup_doc_rev(%DB{server: server, options: opts}=db, doc_id, params \\ []) do
    url = :hackney_url.make_url(server.url, Httpc.doc_url(db, Util.encode_docid(doc_id)), params)

    case Httpc.db_request(:head, url, [], "", opts, [200]) do
      {:ok, resp} ->
        Regex.replace( Regex.compile!("\""), :hackney_headers.parse("etag", resp.headers), "")
      error ->
        error
    end
  end


  # put_attachment
  def put_attachment(%DB{server: server, options: opts}=db, doc_id, name, body, options) do
    query_args = case Keyword.get(options, :rev, nil) do
      nil -> []
      rev -> [rev: rev]
    end
    headers = Keyword.get(options, :headers, [])

    final_headers = List.foldl(options, headers, fn(option, acc) -> 
      case option do
        {:content_length, v} -> [{"Content-Length", Integer.ot_string(v)} | acc]
        {:content_type, v} -> [{"Content-Type", v} | acc]
        _ -> acc
      end
    end)

    doc_id = Util.encode_docid(doc_id)
    att_name = Util.encode_att_name(name)
    url = :hackney_url.make_url(server.url, [db.name, doc_id, att_name], query_args)
    case Httpc.db_request(:put, url, final_headers, body, opts, [201]) do
      {:ok, resp} -> 
        {:ok, json_body} = Httpc.json_body(resp, keys: :atoms)
        {:ok, json_body}
      error ->
        error
    end
  end

  # fetch_attachment
  def fetch_attachment(%DB{server: server, options: opts}=db, doc_id, name, options \\ []) do
    {stream, options} = case Keyword.get(options, :stream) do
      nil ->
        {false, options}
      true ->
        {true, Keyword.delete(options, :stream)}
      _ ->
        {true, Keyword.delete(options, :stream)}
    end

    {options, headers} = case Keyword.get(options, :headers) do
      nil ->
        {options, []}
      headers ->
        {Keyword.delete(options, :headers), headers}
    end

    doc_id = Util.encode_docid(doc_id)
    url = :hackney_url.make_url(server.url, [db.name, doc_id, name], options)

    case HTTPoison.get(url, headers, opts) do
      {:ok, resp} ->
        case resp.status_code do
          200 when stream != true ->
            {:ok, resp.body}
          200 ->
            raise "streaming attachments not implemented (yet)"
          404 ->
            {:error, :not_found}
        end
      {:error, reason} ->
        {:error, reason}
      error ->
        error
    end
  end

  # stream_attachment
  # send_attachment

  # delete_attachment
  def delete_attachment(%DB{server: server, options: opts}=db, doc_or_doc_id, name, options \\ []) do
    {rev, doc_id} = case doc_or_doc_id do
      doc when is_map(doc) ->
        {doc._rev, doc._id}
      doc_id ->
        {options[:_rev], doc_id}
    end
    case rev do
      nil ->
        {:error, :rev_undefined}
      _ ->
        options = case options[:rev] do
          nil ->
            Keyword.put(options, :rev, rev)
          _ ->
            options
        end
        url = :hackney_url.make_url(server.url, [db.name, doc_id, name], options)
        case Httpc.db_request(:delete, url, [], "", opts, [200]) do
          {:ok, resp} ->
            {:ok, json_body} = Httpc.json_body(resp, keys: :atoms)
            {:ok, json_body}
          error ->
            error
        end
    end
  end

  # ensure_full_commit (is this in couchdb-api?)

  #compact database
  def compact(%DB{server: server, options: opts}=db) do
    url = :hackney_url.make_url(server.url, [db.name, "_compact"], [])
    headers = ["Content-Type": "application/json"]
    case Httpc.db_request(:post, url, headers, "", opts, [202]) do
      {:ok, _resp} ->
        :ok
      error ->
        error
    end
  end

  # compact views
  def compact(%DB{server: server, options: opts}=db, design_name) do
    url = :hackney_url.make_url(server.url, [db.name, "_compact", design_name], [])
    headers = ["Content-Type": "application/json"]
    case Httpc.db_request(:post, url, headers, "", opts, [202]) do
      {:ok, _resp} ->
        :ok
      error ->
        error
    end
  end

  # get_missing_revs

  ## PRIVATE
  # maybe_docid
  defp maybe_docid(server, doc, key \\ :_id) do
    case Access.fetch(doc, key) do
      :error when is_atom(key) ->
        maybe_docid(server, doc, Atom.to_string(key))
      :error ->
        [id] = get_uuid(server)
        Map.put(doc, key, id)
      _ ->
        doc
    end
  end
  

  # update_config

end
