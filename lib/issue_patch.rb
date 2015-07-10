require_dependency 'issue'

module RedmineActualPeriod
  module IssuePatch

    extend ActiveSupport::Concern
    included do
      unloadable
      alias_method_chain :validate_issue, :actual_period
    end

    def calclated_actual_start
      result = Issue.periodlist.select("recalc_start").find_by_id(self.id)
      return result ? result.recalc_start.to_date : nil
      
    end

    def calclated_actual_end
      result = Issue.periodlist.select("recalc_end").find_by_id(self.id)
      return result ? result.recalc_end.to_date : nil

    end

    def set_original_and_actual
      if self.new_record? || (self.lft_was.to_i == self.rgt_was.to_i - 1) #only leaf issues
        if !self.original_start && self.start_date
          self.original_start = self.start_date
        end
        if !self.original_due && self.due_date
          self.original_due = self.due_date
        end
        if !self.original_hours && self.estimated_hours
          self.original_hours = self.estimated_hours
        end
      end
      if !self.edit_actualperiod? && !self.new_record?
        self.actual_start = self.calclated_actual_start
        self.actual_end = (self.closed?) ? self.calclated_actual_end : nil
      end
    end

    def original_hours=(h)
      write_attribute :original_hours, (h.is_a?(String) ? h.to_hours : h)
    end

    def validate_issue_with_actual_period
      validate_issue_without_actual_period
      if actual_start && actual_end && (actual_start_changed? || actual_end_changed?) && actual_end < actual_start
        errors.add :actual_end, :greater_than_actual_start
      end
      if original_start && original_due && (original_start_changed? || original_due_changed?) && original_due < original_start
        errors.add :original_due, :greater_than_original_start
      end
      if original_hours_changed? && original_hours && original_hours < 0
        errors.add :original_hours, :invalid
      end
      if original_hours_changed? && !original_hours
        errors.add :original_hours, :empty
      end
      if original_start_changed? && !original_start
        errors.add :original_start, :empty
      end
      if original_due_changed? && !original_due
        errors.add :original_due, :empty
      end

    end
  end
end

RedmineActualPeriod::IssuePatch.tap do |mod|
  Issue.send :include, mod unless Issue.include?(mod)
end
Issue.class_eval do
  before_save :set_original_and_actual
  validates :actual_start, :date => true
  validates :actual_end, :date => true
  validates :original_start, :date => true
  validates :original_due, :date => true
  validates :original_hours, :numericality => {:greater_than_or_equal_to => 0, :allow_nil => true, :message => :invalid}
  safe_attributes 'edit_actualperiod',
    'actual_start',
    'actual_end',
    'original_start',
    'original_due',
    'original_hours',
    :if => lambda {|issue, user| issue.new_record? || user.allowed_to?(:edit_issues, issue.project) }
  scope :periodlist, -> {
    joins(<<-SQL
        INNER JOIN(
          SELECT 
            `main`.`id` `issue_id`,
            MAX(#{TimeEntry.table_name}.spent_on) `recalc_end`,
            MIN(#{TimeEntry.table_name}.spent_on) `recalc_start`
          FROM #{Issue.table_name} AS `main`
          INNER JOIN #{Issue.table_name} AS `child`
            ON `main`.`root_id` = `child`.`root_id` AND `main`.`lft` <= `child`.`lft` AND `child`.`rgt` <= `main`.`rgt`
          INNER JOIN #{TimeEntry.table_name}
            ON `child`.`id` = #{TimeEntry.table_name}.`issue_id`
          INNER JOIN #{TimeEntryActivity.table_name}
            ON #{TimeEntryActivity.table_name}.`type` = 'TimeEntryActivity' AND #{TimeEntryActivity.table_name}.`include_in_calc` = 1 AND #{TimeEntryActivity.table_name}.`id` = #{TimeEntry.table_name}.`activity_id`
          GROUP BY `main`.`id`
        ) `wrk`
          ON #{Issue.table_name}.`id` = `wrk`.`issue_id`
      SQL
      )
  }
end