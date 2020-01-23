defmodule ProjectMenu do
  ### Projects ###
  # [$] ${project_name} ${project status}
  # [A] Add project
  # [B] Back
  def index(state_pid) do
    Terminal.clear
    Terminal.bold "Projects"
    ProjectMenu.list state_pid
    IO.puts "[A] Add project"
    IO.puts "[B] Back"

    option_s = Terminal.ask_option
    {option, option_valid} = Terminal.parse_int(option_s)

    if option_valid && option < State.count state_pid do
      show state_pid, option
    else
      case option_s do
        "A" -> add(state_pid); Router.go_to(:projects, state_pid)
        "B" -> :home; Router.go_to(:home, state_pid)
        _ -> index(state_pid)
      end
    end
  end

  ### Add project ###
  # Name: ...
  def add(state_pid, msgs \\ []) do
    Terminal.clear
    Terminal.bold "Add project"

    if msgs != [], do: Terminal.error(Enum.join(msgs, "\n"))
    msgs = []

    name = Terminal.ask_input("Name:") |> String.trim
    name_valid = name != ""

    msgs = unless name_valid do
      msgs ++ ["Name can't be blank"]
    else
      msgs
    end

    priority = Terminal.ask_input("Priority(0-10, Smaller is less urgent):") |> String.trim
    {priority, priority_valid} = Terminal.parse_int(priority)
    priority_valid = priority_valid && priority <= 10 && priority >= 0

    msgs = unless priority_valid do
      msgs ++ ["Priority not valid"]
    else
      msgs
    end

    due_date = Terminal.ask_input("Due date(yyyy-mm-dd):") |> String.trim |> String.split("-")
    due_date = Enum.map(due_date, fn part -> Terminal.parse_int(part) end)
    due_date_valid = Enum.map(due_date, fn part -> elem(part, 1) end)
    due_date_valid = Enum.reduce(due_date_valid, fn part, acc -> acc && part end)
    due_date = Enum.map(due_date, fn part -> elem(part, 0) end)
    due_date = List.to_tuple(due_date)
    due_date = %Date {
      year: elem(due_date, 0),
      month: elem(due_date, 1),
      day: elem(due_date, 2)
    }

    msgs = unless due_date_valid do
      msgs ++ ["Date not valid"]
    else
      msgs
    end

    project = cond do
      msgs == [] -> Project.new(name, due_date, priority)
      :ok -> nil
    end

    if project != nil do
      State.add state_pid, project
    else
      add state_pid, msgs
    end
  end

  ### Project ###
  # Name: ${project_name}
  # Due date: ${project_due_date}
  # Priority: ${project_priority}
  # Complete: ${project_complete}
  #
  # [E] Edit
  # [D] Delete
  # [B] Back
  def show(state_pid, id) do
    project = State.get(state_pid, id)

    Terminal.clear
    Terminal.bold "Project"
    IO.puts "Name: #{project.name}"
    IO.puts "Due date: #{project.due_date}"
    IO.puts "Priority: #{project.priority}"
    IO.puts "Complete: #{project.complete}"
    IO.puts ""

    IO.puts "[E] Edit"
    IO.puts "[D] Delete"
    IO.puts "[B] Back"

    option = Terminal.ask_option

    case option do
      "E" -> edit(state_pid, id); Router.go_to(:projects, state_pid)
      "D" -> delete(state_pid, id); Router.go_to(:projects, state_pid)
      "B" -> Router.go_to(:projects, state_pid)
      _ -> show(state_pid, id)
    end
  end

  ### Delete ${project_name} ###
  def delete(state_pid, id) do
    project = State.get(state_pid, id)

    Terminal.clear
    Terminal.bold "Delete #{project.name}"
    option = Terminal.ask_input("Are you sure, you want to delete?([y/N])") |> String.trim

    case option do
      "y" -> State.delete(state_pid, id)
      _ -> :ok
    end
  end

  ### Edit ${project_name} ###
  # Name(${project_name}): ...
  def edit(state_pid, id, msgs \\ []) do
    project = State.get(state_pid, id)

    Terminal.clear
    Terminal.bold "Edit #{project.name}"

    if msgs != [], do: Terminal.error(Enum.join(msgs, "\n"))
    msgs = []

    name = Terminal.ask_input("Name(#{project.name}):") |> String.trim
    name = if name == "" do
      project.name
    else
      name
    end

    priority = Terminal.ask_input("Priority(#{project.priority}):") |> String.trim
    {priority, priority_valid} = if priority == "" do
      {project.priority, true}
    else
      {priority, priority_valid} = Terminal.parse_int(priority)
      {priority, priority_valid && priority <= 10 && priority >= 0}
    end

    msgs = unless priority_valid do
      msgs ++ ["Priority not valid"]
    else
      msgs
    end

    due_date = Terminal.ask_input("Due date(#{project.due_date}):") |> String.trim
    {due_date, due_date_valid} = if due_date == "" do
      {project.due_date, true}
    else
      due_date = due_date |> String.split("-")
      due_date = Enum.map(due_date, fn part -> Terminal.parse_int(part) end)
      due_date_valid = Enum.map(due_date, fn part -> elem(part, 1) end)
      due_date_valid = Enum.reduce(due_date_valid, fn part, acc -> acc && part end)
      due_date = Enum.map(due_date, fn part -> elem(part, 0) end)
      due_date = List.to_tuple(due_date)
      if tuple_size(due_date) == 3 do
        due_date = %Date {
          year: elem(due_date, 0),
          month: elem(due_date, 1),
          day: elem(due_date, 2)
        }
        {due_date, due_date_valid}
      else
        {due_date, false}
      end

    end

    msgs = unless due_date_valid do
      msgs ++ ["Date not valid"]
    else
      msgs
    end

    project = cond do
      msgs == [] -> %{ project | name: name, due_date: due_date, priority: priority }
      :ok -> nil
    end

    if project != nil do
      State.update state_pid, id, project
    else
      edit state_pid, id, msgs
    end
  end

  def list(state_pid) do
    projects = State.all state_pid
    list_item 0, projects, State.count state_pid
  end

  def list_item(id, projects, size) do
    if id < size do
      project = projects |> Enum.at(id)
      IO.puts "[#{id}] #{project.name} #{ if project.complete, do: '-> Completed' }"
      list_item id + 1, projects, size
    end
  end
end