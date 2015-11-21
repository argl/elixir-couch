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
  # rep_obj = {[
  #   {<<"source">>, <<"sourcedb">>},
  #   {<<"target">>, <<"targetdb">>},
  #   {<<"create_target">>, true}
  # ]}
  # replicate(Server, RepObj)
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
      error ->
        error
    end
  end



end
