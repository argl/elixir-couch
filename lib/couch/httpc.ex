defmodule Couch.Httpc do

  def json_body(ref, opts \\ %{}) do
    Poison.decode(ref.body, opts)
  end

  def doc_url(db, docid) do
    db.name <> "/" <> docid
  end

  def request(method, url, headers, body, options) do
    {final_headers, final_opts} = make_headers(method, url, headers, options)
    HTTPoison.request(method, url, body, final_headers, final_opts)
  end

  def db_request(method, url, headers, body, options) do
    db_request(method, url, headers, body, options, [])
  end
  def db_request(method, url, headers, body, options, expect) do
    resp = request(method, url, headers, body, options)
    db_resp(resp, expect)
  end

  def db_resp(resp, []) do
    resp
  end
  def db_resp({:ok, resp}, expect) do
    case resp.status_code do
      401 -> {:error, :unauthenticated}
      403 -> {:error, :forbidden}
      404 -> {:error, :not_found}
      409 -> {:error, :conflict}
      412 -> {:error, :precondition_failed}
      _ -> 
        case Enum.member?(expect, resp.status_code) do
          true -> {:ok, resp}
          false -> {:error, {:bad_response, {resp.status_code, resp.headers, ""}}}
        end
    end
  end
  def db_resp({:error, error}, _expect) do
    {:error, error.reason}
  end


  def make_headers(method, url, headers, options) do
    new_headers = case Couch.Util.get_value("Accept", headers) do
      nil ->
        [{"Accept", "application/json, */*;q=0.9"} | headers]
      _ ->
        headers
    end
    maybe_oauth_header(method, url, new_headers, options)
  end

  def maybe_oauth_header(method, url, headers, options) do
    case Couch.Util.get_value(:oauth, options) do
      nil ->
        {headers, options}
      oauth_props ->
        hdr = Couch.Util.oauth_header(url, method, oauth_props)
        {[hdr|headers], List.keydelete(options, :oauth)}
    end
  end

end