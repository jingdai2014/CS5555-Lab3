class CreateSleeps < ActiveRecord::Migration
  def change
    create_table :sleeps do |t|
      t.string :uid
      t.string :date
      t.integer :awakeDuration
      t.integer :awakeningsCount
      t.integer :totalMinutesAsleep
      t.integer :totalTimeInBed

      t.timestamps null: false
    end
  end
end
