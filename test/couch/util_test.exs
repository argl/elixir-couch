defmodule Couch.Test.UtilTest do
  use ExUnit.Case

  alias Couch.Util

  test "get_value" do
    proplist = [{"key1", "value1"}, {"key2", "value2"}]
    assert Util.get_value("key1", proplist)  == "value1"
    assert Util.get_value("key2", proplist, "default")  == "value2"
    assert Util.get_value("key3", proplist, "default")  == "default"
    assert Util.get_value("key3", proplist) == nil
  end


end
