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

  test "propnerge" do
    a = [{"ak1", "av1"}, {"ak2", "av2"}, {"ak3", "av3"}]
    b = [{"bk1", "bv1"}, {"bk2", "bv2"}, {"bk3", "bv3"}]
    c = [{"ak1", "cv1"}]

    merged = Util.propmerge1(a, b)
    assert List.keyfind(merged, "ak1", 0) == {"ak1", "av1"}
    assert List.keyfind(merged, "ak2", 0) == {"ak2", "av2"}
    assert List.keyfind(merged, "ak3", 0) == {"ak3", "av3"}
    assert List.keyfind(merged, "bk1", 0) == {"bk1", "bv1"}
    assert List.keyfind(merged, "bk2", 0) == {"bk2", "bv2"}
    assert List.keyfind(merged, "bk3", 0) == {"bk3", "bv3"}
    merged =  Util.propmerge1(a, c)
    assert List.keyfind(merged, "ak1", 0) == {"ak1", "av1"}
    assert List.keyfind(merged, "ak2", 0) == {"ak2", "av2"}
    assert List.keyfind(merged, "ak3", 0) == {"ak3", "av3"}
    merged =  Util.propmerge1(c, a)
    assert List.keyfind(merged, "ak1", 0) == {"ak1", "cv1"}
    assert List.keyfind(merged, "ak2", 0) == {"ak2", "av2"}
    assert List.keyfind(merged, "ak3", 0) == {"ak3", "av3"}
  end

  test "encode_docid" do
    assert Util.encode_docid("bah/buh") == "bah%2fbuh"
    assert Util.encode_docid("_design/hepp/hopp") == "_design/hepp%2fhopp"
    assert Util.encode_docid("bah buh") == "bah%20buh"
  end

  # test "oath_header" do
    
  # end

end
