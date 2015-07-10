module RedmineActualPeriod
  class ViewHooks < Redmine::Hook::ViewListener

    render_on(:view_issues_show_details_bottom, :partial => "hooks/issues/show_actual_attribute")
    render_on(:view_issues_form_details_bottom, :partial => "hooks/issues/edit_actual_attribute")
    render_on(:view_issues_bulk_edit_details_bottom, :partial => "hooks/issues/bulk_edit_actual")

    def helper_issues_show_detail_after_setting(context={ })
      #{:detail => detail, :label => label, :value => value, :old_value => old_value }
      case context[:detail].prop_key
      when 'original_due', 'original_start', 'actual_end', 'actual_start'
        context[:detail].value = format_date(context[:detail].value.to_date) if context[:detail].value
        context[:detail].old_value  = format_date(context[:detail].old_value.to_date) if context[:detail].old_value
      when 'original_hours'
        context[:detail].value = "%0.02f" % context[:detail].value.to_f unless context[:detail].value.blank?
        context[:detail].old_value = "%0.02f" % context[:detail].old_value.to_f unless context[:detail].old_value.blank?
      when 'edit_actualperiod'
        context[:detail].value = l(context[:detail].value == "0" ? :general_text_No : :general_text_Yes) unless context[:detail].value.blank?
        context[:detail].old_value = l(context[:detail].old_value == "0" ? :general_text_No : :general_text_Yes) unless context[:detail].old_value.blank?
      end
    end

  end
end
