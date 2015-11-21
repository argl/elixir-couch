defmodule Couch.Test.UUIDsTest do
  use ExUnit.Case

  test "random" do
    r = Couch.UUIDs.random
    assert r
    assert String.length(r) == 32
    r2 = Couch.UUIDs.random
    assert r2 != r
  end

  test "utc_random" do
    r = Couch.UUIDs.utc_random
    assert r
    assert String.length(r) == 32
    r2 = Couch.UUIDs.utc_random
    assert r2 != r
    assert r2 > r
  end

  test "get_uuids" do
    uuids = Couch.UUIDs.get_uuids nil, 100
    assert uuids
    assert length(uuids) == 100
    assert String.length(hd(uuids)) == 32
    [u1 | rest ] = uuids
    [u2 | _rest ] = rest
    assert u1 != u2
  end

end
