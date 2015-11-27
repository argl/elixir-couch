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


defmodule Couch.TestHelpers do

  alias Couch.Client

  @dbname "elixir_couch_test"
  @repl_dbname "elixir_couch_test2"
  @create_dbname "elixir_couch_test3"

  def clean_dbs(stuff \\ []) do
    url = Application.get_env(:couch, :url)

    server = Client.server_connection url

    db = %Client.DB{server: server, name: @dbname}
    db2 = %Client.DB{server: server, name: @repl_dbname}
    db3 = %Client.DB{server: server, name: @repl_dbname}

    Client.delete_db(server, @dbname)
    Client.delete_db(server, @repl_dbname)
    Client.delete_db(server, @create_dbname)

    stuff ++ [
      db: db,
      db2: db2,
      db3: db3,
      url: url,
      server: server,
      dbname: @dbname, 
      repl_dbname: @repl_dbname, 
      create_dbname: @create_dbname
    ]
  end

  def create_db(stuff \\ []) do
    {:ok, _db} = Client.create_db(stuff[:server], stuff[:dbname])
    stuff
  end
end

ExUnit.start()

