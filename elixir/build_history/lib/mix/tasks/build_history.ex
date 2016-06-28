# Uses ectool to get the history for a specific project from electric commander,
# and then generates a report.

defmodule Mix.Tasks.BuildHistory do
  use Mix.Task

  @ectool "/opt/electriccloud/electriccommander/bin/ectool"
  @page_size 5000

  @ec_history_cache "/tmp/ec-job-history.json"

  def run(args) do
    project_name = List.first(args)

    IO.puts "Gathering history for #{project_name}..."
    project_history = retrieve_project_history(project_name)

    IO.puts "Analyzing #{Enum.count(project_history)} jobs..."
    results = analyze_project(project_name, project_history)

    display_results(project_name, results)
  end

  defp display_results(project_name, results) do
    IO.puts "Results for #{project_name}"
    IO.puts "------------#{String.rjust("", String.length(project_name), ?-)}"

    unless results[:total_builds] == 0 do
      build_results = "#{results[:build_successes]}/#{results[:total_builds]}"
      build_ratio = results[:build_successes] / results[:total_builds] * 100.0
      IO.puts "Builds:" <> String.rjust(build_results, 10) <> String.rjust("#{round(build_ratio)}", 7) <> "%"
    else
      IO.puts "No Build History Found"
    end

    unless results[:total_validates] == 0 do
      validate_results = "#{results[:validate_successes]}/#{results[:total_validates]}"
      validate_ratio = results[:validate_successes] / results[:total_validates] * 100.0
      IO.puts "Validates:" <> String.rjust(validate_results, 7) <> String.rjust("#{round(validate_ratio)}", 7) <> "%"
    else
      IO.puts "No Validate History Found"
    end
  end

  defp analyze_project(project_name, project_history) do
    builds = Enum.filter(project_history, fn(job) ->
      String.starts_with?(job["jobName"], "#{project_name}-build")
    end)

    validates = Enum.filter(project_history, fn(job) ->
      String.starts_with?(job["jobName"], "#{project_name}-validate")
    end)

    %{
      total_builds: Enum.count(builds),
      build_successes: Enum.count(Enum.filter(builds, fn(job) -> job["outcome"] == "success" end)),
      total_validates: Enum.count(validates),
      validate_successes: Enum.count(Enum.filter(validates, fn(job) -> job["outcome"] == "success" end))
    }
  end

  defp retrieve_project_history(project_name) do
    ec_job_history = retrieve_ec_history
    filter_job_history(project_name, ec_job_history)
  end

  defp filter_job_history(project_name, ec_job_history) do
    Enum.filter(ec_job_history, fn(job) ->
      String.starts_with?(job["jobName"], project_name) && job["status"] == "completed"
    end)
  end

  defp retrieve_ec_history do
    refresh_cache

    Poison.decode!(File.read!(@ec_history_cache))
  end

  defp refresh_cache do
    case File.stat(@ec_history_cache, time: :posix) do
      {:ok, stat_data} -> unless stat_data.mtime > :os.system_time(:seconds) - 4 * 3600 do
          reload_data
        end
      _ -> reload_data
    end
  end

  defp reload_data do
    login_to_ec

    pages = Enum.map(0..20, fn(n) -> retrieve_ec_history_page(n) end)
    job_list = List.foldr(pages, [], fn(x, y) ->
      case x do
        nil -> y
        _ -> x ++ y
      end
    end)

    File.write!(@ec_history_cache, Poison.encode!(job_list))
  end

  defp retrieve_ec_history_page(page_number) do
    result = System.cmd @ectool, ["--format", "json", "getJobs", "--maxResults", "#{@page_size}", "--firstResult", "#{@page_size * page_number}"]
    data_str = Kernel.elem(result, 0)
    Poison.Parser.parse!(data_str)["job"]
  end

  defp login_to_ec do
    System.cmd @ectool, ["login", System.get_env("FSGLOBAL_USERNAME"), System.get_env("FSGLOBAL_PASSWORD")]
  end

end
