Payment.delete_all
Appointment.delete_all
Customer.delete_all
Practitioner.delete_all

Appointment.skip_callback(:save, :after, :notify_status_change)
Appointment.skip_callback(:create, :after, :send_confirmation_email)

begin
  practitioners = [
    { name: "Dr. Maya Chen", email: "maya.chen@bookwell.example", time_zone: "America/New_York" },
    { name: "Jordan Blake", email: "jordan.blake@bookwell.example", time_zone: "America/Chicago" },
    { name: "Sam Rivera", email: "sam.rivera@bookwell.example", time_zone: "America/Los_Angeles" }
  ].map { |attrs| Practitioner.create!(attrs) }

  customers = [
    [ "Ava Thompson", "ava.thompson@example.com" ],
    [ "Noah Patel", "noah.patel@example.com" ],
    [ "Liam Brooks", "liam.brooks@example.com" ],
    [ "Emma Garcia", "emma.garcia@example.com" ],
    [ "Olivia Kim", "olivia.kim@example.com" ],
    [ "Ethan Wright", "ethan.wright@example.com" ],
    [ "Sophia Nguyen", "sophia.nguyen@example.com" ],
    [ "Mason Reed", "mason.reed@example.com" ],
    [ "Isabella Cruz", "isabella.cruz@example.com" ],
    [ "Lucas Bennett", "lucas.bennett@example.com" ],
    [ "Mia Foster", "mia.foster@example.com" ],
    [ "James Ortega", "james.ortega@example.com" ]
  ].map { |name, email| Customer.create!(name: name, email: email) }

  amounts = [ 8_000, 10_000, 12_500, 15_000, 18_000 ]

  now = Time.current.utc
  appointment_count = 0

  (-21..21).each do |day_offset|
    [ 9, 11, 14, 16 ].each_with_index do |hour, slot_index|
      next if day_offset.abs > 14 && slot_index.odd?
      next if day_offset.zero? && hour == 9

      starts_at = (now.to_date + day_offset).in_time_zone("UTC").change(hour: hour, min: 0, sec: 0)
      status =
        if starts_at < now - 1.day
          %i[completed completed no_show].sample
        elsif starts_at < now
          %i[completed no_show confirmed].sample
        else
          :confirmed
        end

      appointment = Appointment.create!(
        practitioner: practitioners.sample,
        customer: customers.sample,
        starts_at: starts_at,
        status: status
      )

      amount = amounts.sample
      deposit = (amount * 0.2).to_i
      appointment.create_payment!(amount_cents: amount, deposit_cents: deposit)
      appointment_count += 1
    end
  end

  puts "Seeded #{practitioners.size} practitioners, #{customers.size} customers, #{appointment_count} appointments."
ensure
  Appointment.set_callback(:save, :after, :notify_status_change)
  Appointment.set_callback(:create, :after, :send_confirmation_email)
end
