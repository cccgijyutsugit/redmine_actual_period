require_dependency 'time_entry'

module RedmineActualPeriod
  module TimeEntryPatch

    extend ActiveSupport::Concern
    included do
      unloadable
    end

    def set_actual_period_to_issue
      basic_issue = Issue.find_by_id(self.issue_id)
      Issue.periodlist.where(" root_id = ? and lft <= ? and rgt >= ? and edit_actualperiod = ? ", basic_issue.root_id, basic_issue.lft, basic_issue.rgt, false).
        update_all("actual_start = recalc_start, actual_end = recalc_end ")
      Issue.joins(:status).merge(IssueStatus.where(:is_closed => false)).where(" root_id = ? and lft <= ? and rgt >= ? and edit_actualperiod = ?", basic_issue.root_id, basic_issue.lft, basic_issue.rgt, false).
        update_all("actual_end = NULL ")
    end
  end
end

# Add module to IssueQuery
RedmineActualPeriod::TimeEntryPatch.tap do |mod|
  TimeEntry.send :include, mod unless TimeEntry.include?(mod)
end
TimeEntry.class_eval do
  after_commit :set_actual_period_to_issue
end