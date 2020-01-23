defmodule App do
  use Application

  def start(_type, _args) do
    Router.go_to
    {:ok, self() }
  end
end