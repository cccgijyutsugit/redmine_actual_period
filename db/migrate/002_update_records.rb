class UpdateRecords < ActiveRecord::Migration
  def up
    # default settings
    TimeEntryActivity.where(:active => true).update_all(:include_in_calc => true)

    # calculate actual period on time entries
    Issue.periodlist.where(:edit_actualperiod => false).update_all("actual_start = recalc_start, actual_end = recalc_end ")
    Issue.joins(:status).merge(IssueStatus.where(:is_closed => false)).where(:edit_actualperiod => false).update_all("actual_end = NULL ")

    # set original schedule from journal records
    Issue.joins(<<-SQL
      INNER JOIN
      (SELECT #{Journal.table_name}.`journalized_id`, #{JournalDetail.table_name}.`old_value`
        FROM #{Journal.table_name} INNER JOIN #{JournalDetail.table_name} ON #{Journal.table_name}.`id` = #{JournalDetail.table_name}.`journal_id`
        WHERE #{Journal.table_name}.`journalized_type` = 'Issue'
        AND #{JournalDetail.table_name}.`property` = 'attr'
        AND #{JournalDetail.table_name}.`prop_key` = 'estimated_hours'
        AND #{Journal.table_name}.`id` = (
          SELECT MIN(`a`.`id`)
          FROM #{Journal.table_name} `a`
          INNER JOIN journal_details `b` ON `a`.`id` = `b`.`journal_id`
          WHERE `a`.`journalized_type` = 'Issue'
          AND `b`.`property` = 'attr'
          AND `b`.`prop_key` = 'estimated_hours'
          AND `a`.`journalized_id` = #{Journal.table_name}.`journalized_id`
          AND `b`.`old_value` IS NOT NULL
        )
      ) wrk ON #{Issue.table_name}.`id`= `wrk`.`journalized_id`
    SQL
    ).where(:original_hours => nil).update_all("original_hours = old_value")
    Issue.joins(<<-SQL
      INNER JOIN
      (SELECT #{Journal.table_name}.`journalized_id`, #{JournalDetail.table_name}.`old_value`
        FROM #{Journal.table_name} INNER JOIN #{JournalDetail.table_name} ON #{Journal.table_name}.`id` = #{JournalDetail.table_name}.`journal_id`
        WHERE #{Journal.table_name}.`journalized_type` = 'Issue'
        AND #{JournalDetail.table_name}.`property` = 'attr'
        AND #{JournalDetail.table_name}.`prop_key` = 'start_date'
        AND #{Journal.table_name}.`id` = (
          SELECT MIN(`a`.`id`)
          FROM #{Journal.table_name} `a`
          INNER JOIN journal_details `b` ON `a`.`id` = `b`.`journal_id`
          WHERE `a`.`journalized_type` = 'Issue'
          AND `b`.`property` = 'attr'
          AND `b`.`prop_key` = 'start_date'
          AND `a`.`journalized_id` = #{Journal.table_name}.`journalized_id`
          AND `b`.`old_value` IS NOT NULL
        )
      ) wrk ON #{Issue.table_name}.`id`= `wrk`.`journalized_id`
    SQL
    ).where(:original_start => nil).update_all("original_start = old_value")
    Issue.joins(<<-SQL
      INNER JOIN
      (SELECT #{Journal.table_name}.`journalized_id`, #{JournalDetail.table_name}.`old_value`
        FROM #{Journal.table_name} INNER JOIN #{JournalDetail.table_name} ON #{Journal.table_name}.`id` = #{JournalDetail.table_name}.`journal_id`
        WHERE #{Journal.table_name}.`journalized_type` = 'Issue'
        AND #{JournalDetail.table_name}.`property` = 'attr'
        AND #{JournalDetail.table_name}.`prop_key` = 'due_date'
        AND #{Journal.table_name}.`id` = (
          SELECT MIN(`a`.`id`)
          FROM #{Journal.table_name} `a`
          INNER JOIN journal_details `b` ON `a`.`id` = `b`.`journal_id`
          WHERE `a`.`journalized_type` = 'Issue'
          AND `b`.`property` = 'attr'
          AND `b`.`prop_key` = 'due_date'
          AND `a`.`journalized_id` = #{Journal.table_name}.`journalized_id`
          AND `b`.`old_value` IS NOT NULL
        )
      ) wrk ON #{Issue.table_name}.`id`= `wrk`.`journalized_id`
    SQL
    ).where(:original_due => nil).update_all("original_due = old_value")
    #only leaf issues
    Issue.where("original_hours is NULL and lft = rgt - 1").update_all("original_hours = estimated_hours")
    Issue.where("original_start is NULL and lft = rgt - 1").update_all("original_start = start_date")
    Issue.where("original_due is NULL and lft = rgt - 1").update_all("original_due = due_date")
  end
end
