class CreateActivities < ActiveRecord::Migration
  def change
    create_table :activities do |t|
      t.string :uid
      t.string :date
      t.integer :steps
      t.integer :failyActiveMinutes
      t.integer :lightlyActiveMinutes
      t.integer :sedentaryMinutes
      t.integer :veryActiveMinutes

      t.timestamps null: false
    end
  end
end
