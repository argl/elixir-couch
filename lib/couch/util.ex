defmodule Couch.Util do

  def get_value(key, prop, default \\ nil) do
    case prop do
      prop when is_map(prop) and is_binary(key) -> 
        case prop[String.to_atom(key)] do
          nil -> default
          value -> value
        end
      prop when is_map(prop) and is_atom(key) -> 
        case prop[key] do
          nil -> default
          value -> value
        end
      prop when is_list(prop) ->
        case List.keyfind(prop, key, 0, default) do
          nil -> 
            case List.keymember?(prop, key, 0) do
              true -> true
              false -> default
            end
          {_key, value} -> value
          other when is_tuple(other) -> default
          _ -> default
        end
    end
  end

  def encode_docid(docid) do
    case docid do
      <<"_design/", rest::binary>> ->
        encoded = :hackney_url.urlencode(rest, [:noplus])
        "_design/" <> encoded
      _ ->
        :hackney_url.urlencode(docid, [:noplus])
    end
  end


  def oauth_header(url, action, oauth_props) do
    {_, _, _, _, _, _, qs, _, _, _, _, _} = :hackney_url.parse_url(url)
    qsl = for {k,v} <- :hackney_url.parse_qs(qs), do: {String.to_char_list(k), String.to_char_list(v)}

    consumer_key = String.to_char_list(get_value(:consumer_key, oauth_props))
    token = String.to_char_list(get_value(:token, oauth_props))
    token_secret = String.to_char_list(get_value(:token_secret, oauth_props))
    consumer_secret = String.to_char_list(get_value(:consumer_secret, oauth_props))
    signature_method_str = String.to_char_list(get_value(:signature_method, oauth_props, "HMAC-SHA1"))

    signature_method_atom = case signature_method_str do
        'PLAINTEXT' ->
            :plaintext;
        'HMAC-SHA1' ->
            :hmac_sha1;
        'RSA-SHA1' ->
            :rsa_sha1
    end
    consumer = {consumer_key, consumer_secret, signature_method_atom}
    method = case action do
        :delete -> 'DELETE'
        :get -> 'GET'
        :post -> 'POST'
        :put -> 'PUT'
        :head -> 'HEAD'
    end
    params = :oauth.sign(method, url, qsl, consumer, token, token_secret) -- qsl
    realm = "OAuth " <> :oauth.header_params_encode(params)
    {"Authorization", List.to_string(realm)}
  end

  def propmerge(f, l1, l2) do
    :dict.to_list(:dict.merge(f, :dict.from_list(l1), :dict.from_list(l2)))
  end

  def propmerge1(l1, l2) do
    propmerge(fn(_, v1, _) -> v1 end, l1, l2)
  end



end