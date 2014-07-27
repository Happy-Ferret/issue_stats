class RepositoriesController < ApplicationController
  before_filter :fetch_report, only: [:show, :refresh]

  def index
    @reports = Report.ready.paginate(page: params[:page])
    @reports = apply_sort(@reports, default: {
      sortable_direction: "ASC",
      sortable_attr: "median_close_time"
    })
  end

  def show
  end

  def refresh
    @report.fetch_metadata
    @report.bootstrap_async
    render nothing: true
  end

  private

  def fetch_report
    @github_key = "#{params[:owner]}/#{params[:repository]}"
    @report = Report.from_key @github_key
  end

  def apply_sort(relation, opts={})
    (default = opts[:default] || {}).stringify_keys
    params.reverse_merge! default
    relation.order("#{params[:sortable_attr]} #{params[:sortable_direction]}")
  end

end
