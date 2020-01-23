defmodule TaskMenu do
  ### Tasks ###
  # [G] Get next task
  # [L] List tasks
  # [B] Back
  def index(state_pid) do
    Terminal.clear
    Terminal.bold "Tasks"
    IO.puts "[G] Get next task"
    IO.puts "[L] List tasks"
    IO.puts "[B] Back"

    op = Terminal.ask_option

    case op do
      "G" -> next(state_pid); Router.go_to(:tasks, state_pid)
      "L" -> list(state_pid); Router.go_to(:tasks, state_pid)
      "B" -> Router.go_to(:home, state_pid)
      _ -> index(state_pid)
    end
  end

  def next(state_pid) do
    { project, id } = State.next(state_pid)
    Terminal.clear
    Terminal.bold "Next task"

    unless project == nil do
      IO.puts "#{project.name} Due date: #{project.due_date} Priority: #{project.priority}"
      IO.puts "[C] Mark as completed"
      IO.puts "[B] Back"

      op = Terminal.ask_option

      case op do
        "C" -> completed(state_pid, id, project)
        _ -> :ok
      end
    else
      Terminal.error "No tasks available"
      IO.puts "[B] Back"

      Terminal.ask_option
    end
  end

  def list(state_pid) do
    Terminal.bold "Tasks"

    projects = State.all(state_pid)
      |> Enum.reject(fn project -> project.complete end)
      |> Enum.sort(&(Project.score(&1) > Project.score(&2)))

    size = Enum.count(projects)

    if size > 0 do
      list_item 0, projects, size
    else
      Terminal.error "No tasks available"
    end

    IO.puts "[B] Back"
    Terminal.ask_option
  end

  def list_item(id, projects, size) do
    if id < size do
      project = projects |> Enum.at(id)
      IO.puts "#{project.name} Due date: #{project.due_date} Priority: #{project.priority}"
      list_item id + 1, projects, size
    end
  end

  def completed(state_pid, id, project) do
    project = %{ project | complete: true }
    State.update state_pid, id, project
  end
end