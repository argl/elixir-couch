defmodule Couch do

  @timeout :infinity

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
        Couch.Httpc.json_body(resp)
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
           status_code when status_code == 200 or status_code ==201 -> Couch.Httpc.json_body(resp)
           _ -> {:error, {:bad_response, {resp.status_code, resp.headers, resp.body}}}
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
    case Couch.Httpc.db_request(:get, url, [], "", opts, [200]) do
      {:ok, resp} ->
        {:ok, all_dbs} = Couch.Httpc.json_body(resp)
        {:ok, all_dbs}
      {:error, reason} ->
        {:error, reason}
    end
  end
  # db_exists
  def db_exists(%Server{url: server_url, options: opts}, db_name) do
    url = :hackney_url.make_url(server_url, db_name, [])
    case Couch.Httpc.db_request(:head, url, [], "", opts, [200]) do
      {:ok, _resp} ->
        true
      _error ->
        false
    end
  end
  # create_db
  def create_db(%Server{url: server_url, options: opts} = server, db_name, options \\ [], params \\ []) do
    merged_options = Couch.Util.propmerge1(options, opts)
    url = :hackney_url.make_url(server_url, db_name, params)
    case Couch.Httpc.db_request(:put, url, [], "", merged_options, [201]) do
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
    case Couch.Httpc.db_request(:delete, url, [], "", opts, [200]) do
      {:ok, resp} ->
        {:ok, response} = Couch.Httpc.json_body(resp)
        {:ok, response}
      error ->
        error
    end

  end

  # open_db
  def open_db(%Server{options: opts} = server, db_name, options \\ []) do
    merged_options = Couch.Util.propmerge1(options, opts)
    {:ok, %DB{server: server, name: db_name, options: merged_options}}
  end
  # open_or_create_db
  def open_or_create_db(%Server{url: server_url, options: opts} = server, db_name, options \\ [], params \\ []) do
    url = :hackney_url.make_url(server_url, db_name, [])
    merged_options = Couch.Util.propmerge1(options, opts)
    response = Couch.Httpc.db_request(:head, url, [], "", merged_options)
    case Couch.Httpc.db_resp(response, [200]) do
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
    case Couch.Httpc.db_request(:get, url, [], "", options, [200]) do
      {:ok, resp} ->
        {:ok, infos} = Couch.Httpc.json_body(resp)
        {:ok, infos}
      {:error, :not_found} ->
        {:error, :db_not_found}
      error ->
        error
    end
  end

  # doc_exists
  # open_doc
  
  # stream_doc
  # end_doc_stream

  # save_doc
  # save_docs
  # delete_doc
  # delete_docs
  # copy_doc
  # do_copy (?)

  # lookup_doc_rev

  # fetch_attachment
  # stream_attachment
  # put_attachment
  # send_attachment
  # delete_attachment

  # ensure_full_commit (is this in couchdb-api?)

  # compact
  # get_missing_revs

  ## PRIVATE
  # maybe_docid
  # update_config











end
