defmodule Couch.Httpc do

  def json_body(ref) do
    Poison.decode(ref.body)
  end

end