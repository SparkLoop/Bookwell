class AddSlugAndCancelledAtToAppointments < ActiveRecord::Migration[7.2]
  def up
    add_column :appointments, :slug, :string
    add_column :appointments, :cancelled_at, :datetime

    Appointment.find_each { |a| a.update_column(:slug, SecureRandom.uuid) }

    change_column_null :appointments, :slug, false
    add_index :appointments, :slug, unique: true
  end

  def down
    remove_index :appointments, :slug
    remove_column :appointments, :slug
    remove_column :appointments, :cancelled_at
  end
end
