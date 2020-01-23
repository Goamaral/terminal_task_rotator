defmodule Project do
  @derive [Poison.Encoder]
  defstruct name: "", complete: false, due_date: Date.utc_today, priority: 0

  def new(name \\ "", due_date \\ Date.utc_today, priority \\ 0, complete \\ false) do
    %Project{ name: name, complete: complete, priority: priority, due_date: due_date }
  end

  def score(project) do
    days = Date.diff(project.due_date, Date.utc_today)
    priority = project.priority + 1

    if days < 0 do
      -1 * days * priority
    else 
      if days > 0 do
        priority / days
      else
        priority
      end
    end
  end
end