class AppointmentMailer < ApplicationMailer
  default from: "bookings@bookwell.example"

  def status_changed(appointment)
    @appointment = appointment
    @customer = appointment.customer
    @practitioner = appointment.practitioner

    mail(
      to: @customer.email,
      cc: @practitioner.email,
      subject: "Appointment status updated to #{appointment.status.humanize}"
    )
  end

  def confirmation(appointment)
    @appointment = appointment
    @customer = appointment.customer
    @practitioner = appointment.practitioner

    mail(
      to: @customer.email,
      cc: @practitioner.email,
      subject: "Appointment confirmation"
    )
  end
end
