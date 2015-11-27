defmodule Couch.ViewSupervisor do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    :ets.new(:couchbeam_view_streams, [:set, :public, :named_table])
    # children = [
    #   supervisor(Couch.ViewStream, [])
    # ]
    # supervise(children, strategy: :simple_one_for_one)
  end
end