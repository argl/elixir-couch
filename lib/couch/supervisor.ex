defmodule Couch.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      # worker(Couch.UUIDs, [[name: "Couch.UUIDs"]]),
      # supervisor(Couch.ViewSupervisor, [[name: "Couch.ViewSupervisor"]])
      # supervisor(Couch.ChangesSupervisor, [[name: "Couch.ChangesSupervisor"]])
    ]
    supervise(children, strategy: :one_for_one)
  end
end