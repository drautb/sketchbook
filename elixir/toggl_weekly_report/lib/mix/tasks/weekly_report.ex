defmodule Mix.Tasks.WeeklyReport do
  use Mix.Task

  @workspace_id 379448
  @toggl_key_env_name "TOGGL_API_KEY"
  @weekly_report_url "https://toggl.com/reports/api/v2/weekly"
  @ms_per_hour 3600000

  def run(args) do
    project_name = List.first(args)

    IO.puts "Getting weekly report data for #{project_name}..."
    weekly_report_data = retrieve_weekly_report(project_name)
    results = summarize_report_data(weekly_report_data)

    display_results(project_name, results)
  end

  defp retrieve_weekly_report(project_name) do
    query_params = %{
      workspace_id: @workspace_id,
      user_agent: "api"
    }
    headers = [Authorization: Base.url_encode64(System.get_env(@toggl_key_env_name))]

    HTTPotion.start
    response = HTTPotion.get! @weekly_report_url, query: query_params, headers: headers
    data = Poison.decode!(response.body)["data"]

    Enum.find(data, %{}, fn(project) -> project["title"]["project"] == project_name end)
  end

  defp summarize_report_data(weekly_report_data) do
    {date, _} = :calendar.local_time
    day_of_week = :calendar.day_of_the_week(date)

    totals = Enum.slice(weekly_report_data["totals"], 7 - day_of_week, day_of_week)
    totals = Enum.reject(totals, fn(x) -> x == nil end)

    week_total_ms = Enum.sum(totals)

    %{total_hours: week_total_ms / @ms_per_hour}
  end

  defp display_results(project_name, results) do
    IO.puts "Total hours this week for #{project_name}: #{Float.round(results.total_hours, 2)}"
  end

end
