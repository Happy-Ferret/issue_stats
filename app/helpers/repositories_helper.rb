module RepositoriesHelper
  def response_distribution_chart report
    categories = Issue.duration_tiers.map do |tier|
      distance_of_time_in_words(tier)
    end

    chart = LazyHighCharts::HighChart.new('graph') do |f|
      f.title(:text => "Distribution of Time to Close an Issue")
      # f.series name: "All Issues", data: report.basic_distribution.values
      f.series name: "Issues", data: report.issues_distribution.values
      f.series name: "Pull Requests", data: report.pr_distribution.values
      f.xAxis categories: categories, labels: {rotation: -45, align: 'right'}

      f.legend(align: 'right', verticalAlign: 'top', floating: true)
      f.chart defaultSeriesType: "column"
      f.labels style: {"font-size" => "10px"}
      f.plotOptions column: { stacking: 'normal' }
    end

    high_chart "repository-issue-distribution", chart
  end

  def duration_with_style duration
    variant = "label" # "text"
    if duration < 1.day
      style = "pull-right #{variant} #{variant}-success"
    elsif duration < 5.days
      style = "pull-right #{variant} #{variant}-info"
    elsif duration < 15.days
      style = "pull-right #{variant} #{variant}-warning"
    elsif duration < 30.days
      style = "pull-right #{variant} #{variant}-danger"
    end
    content_tag :span, class: style do
      distance_of_time_in_words(duration).titleize + " to Close an Issue"
    end
  end

  def badge_color(report)
    index = report.duration_index
    colors = %w(#00bc8c #3498DB #AC6900 #E74C3C)
    colors[index / 2] || colors.last
  end
end
