class AddMinutesBeforeAsleepToSleeps < ActiveRecord::Migration
  def change
  	add_column :sleeps, :minutesToFallAsleep, :integer
  end
end
