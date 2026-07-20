class AppointmentsController < ApplicationController
  before_action :set_appointment, only: %i[show edit update]

  def index
    @appointments = Appointment.order(:starts_at)
  end

  def show
  end

  def edit
  end

  def update
    if @appointment.update(appointment_params)
      redirect_to @appointment, notice: "Status updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_appointment
    @appointment = Appointment.find(params[:id])
  end

  def appointment_params
    params.require(:appointment).permit(:status)
  end
end
