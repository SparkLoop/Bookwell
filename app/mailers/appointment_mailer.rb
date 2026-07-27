class AppointmentMailer < ApplicationMailer
  default from: "bookings@bookwell.example"

  def status_changed(appointment)
    @appointment = appointment
    @customer = appointment.customer
    @practitioner = appointment.practitioner

    mail(
      to:      @customer.email,
      cc:      @practitioner.email,
      subject: t(".subject", status: appointment.status.humanize)
    )
  end

  def cancellation_confirmation(appointment)
    @appointment = appointment
    @customer    = appointment.customer
    @practitioner = appointment.practitioner

    mail(
      to:      @customer.email,
      subject: t(".subject", date: appointment.display_time)
    )
  end

  def practitioner_cancellation_notification(appointment)
    @appointment  = appointment
    @customer     = appointment.customer
    @practitioner = appointment.practitioner

    mail(
      to:      @practitioner.email,
      subject: t(".subject", customer: @customer.name, date: appointment.display_time)
    )
  end

  def confirmation(appointment)
    @appointment = appointment
    @customer = appointment.customer
    @practitioner = appointment.practitioner

    mail(
      to:      @customer.email,
      cc:      @practitioner.email,
      subject: t(".subject")
    )
  end
end
