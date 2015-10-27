class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :id
      t.string :gender
      t.string :dob
      t.string :token

      t.timestamps null: false
    end
  end
end
