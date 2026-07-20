class Appointment < ApplicationRecord
  belongs_to :practitioner
  belongs_to :customer
  has_one :payment, dependent: :destroy

  enum :status, { confirmed: 0, completed: 1, no_show: 2 }

  validates :starts_at, presence: true
  validates :status, presence: true

  after_save :notify_status_change

  def notify_status_change
    return unless saved_change_to_status?

    AppointmentMailer.status_changed(self).deliver_now
  end

  def confirm!
    update!(status: :confirmed)
  end

  def complete!
    update!(status: :completed)
  end

  def mark_no_show!
    update!(status: :no_show)
  end

  def display_time
    starts_at.strftime("%b %-d, %Y at %-l:%M %p")
  end

  def short_date
    starts_at.strftime("%b %-d")
  end

  def day_label
    today = Time.current.to_date
    date = starts_at.to_date

    if date == today
      "Today"
    elsif date == today + 1
      "Tomorrow"
    elsif date == today - 1
      "Yesterday"
    else
      starts_at.strftime("%A")
    end
  end

  def time_range(duration_minutes = 60)
    ends_at = starts_at + duration_minutes.minutes
    "#{starts_at.strftime('%-l:%M %p')} – #{ends_at.strftime('%-l:%M %p')}"
  end

  def clock_time
    starts_at.strftime("%-l:%M %p")
  end

  def full_timestamp
    starts_at.strftime("%Y-%m-%d %H:%M:%S UTC")
  end

  def amount_paid
    return 0.0 if payment.nil?

    payment.amount_cents / 100.0
  end

  def deposit_paid
    return 0.0 if payment.nil?

    payment.deposit_cents / 100.0
  end

  def balance_due
    return 0.0 if payment.nil?

    (payment.amount_cents - payment.deposit_cents) / 100.0
  end

  def refund_amount
    return 0.0 if payment.nil?

    payment.amount_cents / 100.0 * 0.5
  end

  def refund_percentage
    within_24h? ? 0.5 : 1.0
  end

  def deposit_forfeit
    return 0.0 if payment.nil?

    payment.deposit_cents / 100.0
  end

  def service_fee
    return 0.0 if payment.nil?

    payment.amount_cents / 100.0 * 0.029 + 0.30
  end

  def outstanding_balance
    return 0.0 if payment.nil?

    (payment.amount_cents - payment.deposit_cents) / 100.0
  end

  def net_after_fees
    amount_paid - service_fee
  end

  def upcoming?
    starts_at >= Time.current
  end

  def past?
    starts_at < Time.current
  end

  def soon?
    starts_at > Time.current && starts_at <= 24.hours.from_now
  end

  def starting_soon?
    starts_at > Time.current && starts_at <= 2.hours.from_now
  end

  def within_24h?
    (starts_at - Time.current).abs <= 24.hours
  end

  def hours_until
    ((starts_at - Time.current) / 1.hour).round
  end

  def minutes_until
    ((starts_at - Time.current) / 1.minute).round
  end

  def starts_today?
    starts_at.to_date == Time.current.to_date
  end

  def relative_time_phrase
    hours = hours_until

    if past?
      "#{hours.abs} hours ago"
    elsif hours < 1
      "in less than an hour"
    elsif hours == 1
      "in about an hour"
    else
      "in #{hours} hours"
    end
  end

  def proximity_label
    if starting_soon?
      "Starting soon"
    elsif soon?
      "Within a day"
    elsif upcoming?
      "Upcoming"
    else
      "Past"
    end
  end

  def self.todays_schedule
    where(starts_at: Time.current.beginning_of_day..Time.current.end_of_day)
      .order(:starts_at)
  end

  def self.upcoming_for(practitioner)
    where(practitioner: practitioner)
      .where("starts_at >= ?", Time.current)
      .order(:starts_at)
  end

  def self.recent_for(customer, limit = 10)
    where(customer: customer)
      .order(starts_at: :desc)
      .limit(limit)
  end

  def self.no_show_rate
    return 0.0 if count.zero?

    no_show.count / count.to_f
  end

  def self.completion_rate
    return 0.0 if count.zero?

    completed.count / count.to_f
  end

  def self.total_revenue
    Payment.sum(:amount_cents) / 100.0
  end

  def self.total_deposits
    Payment.sum(:deposit_cents) / 100.0
  end

  def self.busiest_practitioner
    grouped = group(:practitioner_id).order(Arel.sql("count(*) DESC")).limit(1).count
    return nil if grouped.empty?

    Practitioner.find_by(id: grouped.keys.first)
  end

  def self.confirmed_upcoming
    confirmed.where("starts_at >= ?", Time.current).order(:starts_at)
  end

  def self.needs_follow_up
    where(status: [ :completed, :no_show ])
      .where("starts_at >= ?", 7.days.ago)
      .order(starts_at: :desc)
  end
end
