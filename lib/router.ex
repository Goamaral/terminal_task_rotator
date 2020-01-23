defmodule Router do
  def go_to(route \\ :home, state_pid \\ nil) do
    state_pid = cond do
      state_pid == nil -> build_state()
      true -> state_pid
    end

    case route do
      :home -> TerminalTaskRotator.index(state_pid)
      :projects -> ProjectMenu.index(state_pid)
      :tasks -> TaskMenu.index(state_pid)
      :exit -> 
        export_state(state_pid)
        clear_state(state_pid)
    end
  end

  def build_state do
    ps = import_state()
    State.start_link(ps) |> elem(1)
  end

  def import_state do
    file_t = File.read "projects.json"
    if file_t |> elem(0) == :ok do
      Poison.decode!(file_t |> elem(1), as: [%Project{}])
    else
      []
    end
  end

  def clear_state(state_pid) do
    State.stop state_pid
  end

  def export_state(state_pid) do
    File.write("projects.json", Poison.encode!(State.all(state_pid)))
  end
end