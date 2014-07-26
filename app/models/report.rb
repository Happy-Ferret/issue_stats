class Report < ActiveRecord::Base
  serialize :basic_distribution, Hash
  serialize :pr_distribution, Hash
  serialize :issues_distribution, Hash

  after_create :bootstrap_async

  class << self
    def from_key key
      report = self.find_or_create_by(github_key: key)
    end
  end

  def bootstrap_async
    GH.repo github_key # ensure repo exists
    Rails.configuration.queue << Afterparty::BasicJob.new(self, :bootstrap)
  end

  def bootstrap
    day_split = 8.0
    setup_distributions
    self.issues_count = issues.size
    issues.each do |issue|
      duration = issue.duration
      Issue.duration_tiers.each_with_index do |tier, index|
        last_tier = index == 0 ? 0 : Issue.duration_tiers[index-1]
        if (duration <= tier) && (duration > last_tier)
          basic_distribution[tier] += 1
          if issue.pull_request
            pr_distribution[tier] += 1
          else
            issues_distribution[tier] += 1
          end
        end
      end
    end
    self.median_close_time = issues.map(&:duration).median
    save!
  end

  def issues
    @issues ||= Issue.find github_key, state: 'closed'
  end

  def ready?
    !!issues_count
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
