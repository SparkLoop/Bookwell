class CustomerAppointmentsController < ApplicationController
  before_action :set_appointment

  def show
  end

  def cancel
    if @appointment.cancellable?
      @appointment.cancel!
      redirect_to customer_appointment_path(@appointment.slug),
                  notice: t("customer_appointments.cancel.success")
    elsif @appointment.cancelled?
      redirect_to customer_appointment_path(@appointment.slug),
                  notice: t("customer_appointments.cancel.already_cancelled")
    else
      redirect_to customer_appointment_path(@appointment.slug),
                  notice: t("customer_appointments.cancel.not_cancellable")
    end
  end

  private

  def set_appointment
    @appointment = Appointment.find_by!(slug: params[:slug])
  rescue ActiveRecord::RecordNotFound
    render plain: t("customer_appointments.cancel.not_found"), status: :not_found
  end
end
