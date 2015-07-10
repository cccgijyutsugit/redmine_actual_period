class AddOriginalColumns < ActiveRecord::Migration
  def change
    add_column :enumerations, :include_in_calc, :boolean, :default => false
    add_column :issues, :actual_start, :date, :default => nil
    add_column :issues, :actual_end, :date, :default => nil
    add_column :issues, :edit_actualperiod, :boolean, :default => false
    add_column :issues, :original_hours, :float, :default => nil
    add_column :issues, :original_start, :date, :default => nil
    add_column :issues, :original_due, :date, :default => nil
  end
end
