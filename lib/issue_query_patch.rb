require_dependency 'issue_query'

module RedmineActualPeriod
  module IssueQueryPatch

    extend ActiveSupport::Concern
    included do
      unloadable
      alias_method_chain :available_filters, :actual_period
      alias_method_chain :available_columns, :actual_period
    end

    def available_filters_with_actual_period
      @available_filters = available_filters_without_actual_period
      
      actual_period_filters = {
        "actual_start" => { 
          :name => l(:field_actual_start),
          :type => :date, 
          :order => @available_filters.size + 1},
        "actual_end" => { 
          :name => l(:field_actual_end),
          :type => :date, 
          :order => @available_filters.size + 2},
        "original_hours" => { 
          :name => l(:field_original_hours),
          :type => :float, 
          :order => @available_filters.size + 3},
        "original_start" => { 
          :name => l(:field_original_start),
          :type => :date, 
          :order => @available_filters.size + 4},
        "original_due" => { 
          :name => l(:field_original_due),
          :type => :date, 
          :order => @available_filters.size + 5}
      }

      return @available_filters.merge!(actual_period_filters)
    end

    def available_columns_with_actual_period
      @available_columns = available_columns_without_actual_period
      if !@actual_period_columns_count
        @available_columns.push(QueryColumn.new(:actual_start, :sortable => "#{Issue.table_name}.actual_start"))
        @available_columns.push(QueryColumn.new(:actual_end, :sortable => "#{Issue.table_name}.actual_end"))
        @available_columns.push(QueryColumn.new(:original_hours, :sortable => "#{Issue.table_name}.original_hours"))
        @available_columns.push(QueryColumn.new(:original_start, :sortable => "#{Issue.table_name}.original_start"))
        @available_columns.push(QueryColumn.new(:original_due, :sortable => "#{Issue.table_name}.original_due"))
        @actual_period_columns_count = @available_columns.length
      end
      return @available_columns
    end
  end
end

# Add module to IssueQuery
RedmineActualPeriod::IssueQueryPatch.tap do |mod|
  IssueQuery.send :include, mod unless IssueQuery.include?(mod)
end