class CreatePractitioners < ActiveRecord::Migration[7.2]
  def change
    create_table :practitioners do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :time_zone, null: false, default: "UTC"

      t.timestamps
    end
  end
end
