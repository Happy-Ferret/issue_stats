class Report < ActiveRecord::Base
  serialize :basic_distribution, Hash
  serialize :pr_distribution, Hash
  serialize :issues_distribution, Hash

  after_create :bootstrap_async

  scope :ready, -> { where("median_close_time is not null") }

  class << self
    def from_key key
      report = self.find_or_create_by(github_key: key)
    end
  end

  def bootstrap_async
    GH.repo github_key # ensure repo exists
    BootstrapReport.enqueue id
  end

  def bootstrap
    day_split = 8.0
    setup_distributions
    self.issues_count = 0
    durations = []
    _self = self
    begin
      issues do |issue|
        durations << issue.duration
        _self.issues_count += 1
        tier = issue.duration_tier
        _self.basic_distribution[tier] += 1
        if issue.pull_request
          _self.pr_distribution[tier] += 1
        else
          _self.issues_distribution[tier] += 1
        end
      end
    rescue Octokit::ClientError
      self.issues_disabled = true
    end
    self.issues_count = _self.issues_count
    self.basic_distribution = _self.basic_distribution
    self.pr_distribution = _self.pr_distribution
    self.issues_distribution = _self.issues_distribution
    self.median_close_time = durations.median
    save!
  end

  def issues &block
    Issue.find(github_key, {state: 'closed'}, block)
  end

  def ready?
    !!median_close_time
  end

  def setup_distributions
    hash = Hash.new(0)
    self.basic_distribution = hash.clone
    self.pr_distribution = hash.clone
    self.issues_distribution = hash.clone
    Issue.duration_tiers.each do |tier|
      basic_distribution[tier] = 0
      pr_distribution[tier] = 0
      issues_distribution[tier] = 0
    end
  end

  def distribution(type, tier)
    send("#{type}_distribution")[tier.to_i]
  end
end
