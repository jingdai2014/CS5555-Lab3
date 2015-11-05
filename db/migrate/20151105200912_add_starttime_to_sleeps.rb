class AddStarttimeToSleeps < ActiveRecord::Migration
  def change
  	add_column :sleeps, :startTime, :string
  end
end
