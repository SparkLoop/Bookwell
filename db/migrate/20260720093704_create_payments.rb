class CreatePayments < ActiveRecord::Migration[7.2]
  def change
    create_table :payments do |t|
      t.integer :amount_cents, null: false, default: 0
      t.integer :deposit_cents, null: false, default: 0
      t.references :appointment, null: false, foreign_key: true, index: { unique: true }

      t.timestamps
    end
  end
end
