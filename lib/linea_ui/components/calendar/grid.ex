defmodule LineaUI.Components.Calendar.Grid do
  @moduledoc false

  @row_px 44
  @weekdays %{
    0 => :sunday,
    1 => :monday,
    2 => :tuesday,
    3 => :wednesday,
    4 => :thursday,
    5 => :friday,
    6 => :saturday
  }

  @spec row_px() :: pos_integer()
  def row_px, do: @row_px

  @spec to_date(term()) :: Date.t() | nil
  def to_date(%Date{} = date), do: date

  def to_date(text) when is_binary(text) do
    case Date.from_iso8601(text) do
      {:ok, date} -> date
      {:error, _reason} -> nil
    end
  end

  def to_date(_value), do: nil

  @spec minutes(term()) :: non_neg_integer() | nil
  def minutes(%Time{hour: hour, minute: minute}), do: hour * 60 + minute

  def minutes(text) when is_binary(text) do
    case Regex.run(~r/\A(\d{1,2}):(\d{2})/, text) do
      [_, hour, minute] -> String.to_integer(hour) * 60 + String.to_integer(minute)
      nil -> nil
    end
  end

  def minutes(_value), do: nil

  @spec clock(non_neg_integer()) :: String.t()
  def clock(minutes) do
    [div(minutes, 60), rem(minutes, 60)]
    |> Enum.map_join(":", &(&1 |> Integer.to_string() |> String.pad_leading(2, "0")))
  end

  defp offset(date, week_start),
    do: Date.day_of_week(date, Map.fetch!(@weekdays, week_start)) - 1

  @spec month_weeks(Date.t(), 0..6) :: [[Date.t()]]
  def month_weeks(date, week_start) do
    first = Date.beginning_of_month(date)
    lead = offset(first, week_start)
    count = ceil((lead + Date.days_in_month(date)) / 7) * 7

    first
    |> Date.add(-lead)
    |> Date.range(Date.add(first, count - lead - 1))
    |> Enum.chunk_every(7)
  end

  @spec week_days(Date.t(), 0..6, boolean()) :: [Date.t()]
  def week_days(date, week_start, weekends?) do
    first = Date.add(date, -offset(date, week_start))

    first
    |> Date.range(Date.add(first, 6))
    |> Enum.filter(&(weekends? or Date.day_of_week(&1) < 6))
  end

  @spec range(Date.t(), String.t(), 0..6) :: {Date.t(), Date.t()}
  def range(date, "month", week_start) do
    weeks = month_weeks(date, week_start)
    {weeks |> hd() |> hd(), weeks |> List.last() |> List.last()}
  end

  def range(date, "week", week_start) do
    first = Date.add(date, -offset(date, week_start))
    {first, Date.add(first, 6)}
  end

  @spec shift(Date.t(), String.t(), :prev | :next) :: Date.t()
  def shift(date, "month", :prev), do: Date.shift(date, month: -1)
  def shift(date, "month", :next), do: Date.shift(date, month: 1)
  def shift(date, "week", :prev), do: Date.add(date, -7)
  def shift(date, "week", :next), do: Date.add(date, 7)

  @spec events([term()]) :: %{Date.t() => [map()]}
  def events(events) do
    events
    |> Enum.flat_map(&event/1)
    |> Enum.sort_by(&(&1.from || -1))
    |> Enum.group_by(& &1.date)
  end

  defp event(event) do
    event = Map.new(event)
    from = minutes(event[:start])

    case to_date(event[:date]) do
      nil ->
        []

      date ->
        [
          %{
            id: event[:id],
            title: event[:title],
            subtitle: event[:subtitle],
            color: event[:color] || "primary",
            date: date,
            from: from,
            to: minutes(event[:end]) || (from && from + 60)
          }
        ]
    end
  end

  @spec blocks([map()], integer(), integer()) :: [map()]
  def blocks(events, day_start, day_end) do
    events
    |> Enum.filter(& &1.from)
    |> Enum.group_by(&hour(&1, day_start, day_end))
    |> Enum.flat_map(fn {hour, group} ->
      group
      |> Enum.with_index()
      |> Enum.map(fn {event, index} -> block(event, hour, index, length(group), day_start) end)
    end)
  end

  defp hour(event, day_start, day_end),
    do: event.from |> div(60) |> max(day_start) |> min(day_end - 1)

  defp block(event, hour, index, count, day_start) do
    inside? = div(event.from, 60) == hour and hour >= day_start
    top = (inside? && round(rem(event.from, 60) / 60 * @row_px) + 1) || 1
    height = max(round((event.to - event.from) / 60 * @row_px) - 3, 20)

    %{
      event: event,
      hour: hour,
      style:
        "top: #{top}px; height: #{height}px; left: calc(#{round(index * 100 / count)}% + 2px); width: calc(#{round(100 / count)}% - 4px)"
    }
  end
end
