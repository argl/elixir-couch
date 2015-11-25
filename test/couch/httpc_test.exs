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


defmodule Couch.Test.HttpcTest do
  use ExUnit.Case

  test "json_body" do
    assert Couch.Httpc.json_body( %HTTPoison.Response{body: "{\"id\": 123}"} ) == {:ok, %{"id" => 123}}
    assert Couch.Httpc.json_body( %HTTPoison.Response{body: "invalid"} ) == {:error, {:invalid, "i"}}
  end

  test "doc_url" do
    db = %Couch.DB{name: "database"}
    docid = "docid"
    assert Couch.Httpc.doc_url(db, docid) == "database/docid"
  end

  test "request" do
  end

  test "db_request" do
  end

  test "db_resp" do
  end

  test "make_headers" do
  end

end
