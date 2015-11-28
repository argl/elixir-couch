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


defmodule Couch.Test.View do
  use ExUnit.Case

  test "all_docs" do
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
