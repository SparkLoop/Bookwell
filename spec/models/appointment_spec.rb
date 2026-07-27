require "rails_helper"

RSpec.describe Appointment, type: :model do
  # ---------------------------------------------------------------------------
  # Associations
  # ---------------------------------------------------------------------------
  it { is_expected.to belong_to(:practitioner) }
  it { is_expected.to belong_to(:customer) }
  it { is_expected.to have_one(:payment).dependent(:destroy) }

  # ---------------------------------------------------------------------------
  # Validations
  # ---------------------------------------------------------------------------
  it { is_expected.to validate_presence_of(:starts_at) }
  it { is_expected.to validate_presence_of(:status) }

  # ---------------------------------------------------------------------------
  # Enum
  # ---------------------------------------------------------------------------
  it do
    is_expected.to define_enum_for(:status)
      .with_values(confirmed: 0, completed: 1, no_show: 2, cancelled: 3)
  end

  # ---------------------------------------------------------------------------
  # Slug generation
  # ---------------------------------------------------------------------------
  describe "#generate_slug" do
    it "assigns a UUID slug on create" do
      appointment = create(:appointment)
      expect(appointment.slug).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/)
    end

    it "does not overwrite an existing slug" do
      existing = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
      appointment = create(:appointment, slug: existing)
      expect(appointment.slug).to eq(existing)
    end
  end

  # ---------------------------------------------------------------------------
  # Status transitions
  # ---------------------------------------------------------------------------
  describe "#cancel!" do
    it "sets status to cancelled" do
      appointment = create(:appointment)
      appointment.cancel!
      expect(appointment).to be_cancelled
    end

    it "stamps cancelled_at" do
      freeze_time do
        appointment = create(:appointment)
        appointment.cancel!
        expect(appointment.cancelled_at).to eq(Time.current)
      end
    end

    it "persists cancelled_at to the database" do
      appointment = create(:appointment)
      appointment.cancel!
      expect(appointment.reload.cancelled_at).not_to be_nil
    end

    it "sends a cancellation confirmation to the customer" do
      appointment = create(:appointment)
      expect { appointment.cancel! }
        .to change { ActionMailer::Base.deliveries.count }.by(2)

      customer_mail = ActionMailer::Base.deliveries[-2]
      expect(customer_mail.to).to eq([ appointment.customer.email ])
      expect(customer_mail.cc).to be_nil.or(be_empty)
    end

    it "sends a separate notification to the practitioner" do
      appointment = create(:appointment)
      appointment.cancel!

      practitioner_mail = ActionMailer::Base.deliveries.last
      expect(practitioner_mail.to).to eq([ appointment.practitioner.email ])
    end
  end

  describe "#confirm!" do
    it "sets status to confirmed" do
      appointment = create(:appointment, :past)
      appointment.update_column(:status, :no_show)
      appointment.confirm!
      expect(appointment).to be_confirmed
    end
  end

  describe "#complete!" do
    it "sets status to completed" do
      appointment = create(:appointment)
      appointment.complete!
      expect(appointment).to be_completed
    end
  end

  describe "#mark_no_show!" do
    it "sets status to no_show" do
      appointment = create(:appointment)
      appointment.mark_no_show!
      expect(appointment).to be_no_show
    end
  end

  # ---------------------------------------------------------------------------
  # Temporal predicates
  # ---------------------------------------------------------------------------
  describe "#upcoming?" do
    it "returns true when starts_at is in the future" do
      appointment = build(:appointment, starts_at: 1.hour.from_now)
      expect(appointment).to be_upcoming
    end

    it "returns false when starts_at is in the past" do
      appointment = build(:appointment, starts_at: 1.hour.ago)
      expect(appointment).not_to be_upcoming
    end
  end

  describe "#past?" do
    it "returns true when starts_at is in the past" do
      appointment = build(:appointment, starts_at: 1.hour.ago)
      expect(appointment).to be_past
    end

    it "returns false when starts_at is in the future" do
      appointment = build(:appointment, starts_at: 1.hour.from_now)
      expect(appointment).not_to be_past
    end
  end

  describe "#within_48h?" do
    it "returns true when the appointment is less than 48 hours away" do
      appointment = build(:appointment, starts_at: 24.hours.from_now)
      expect(appointment).to be_within_48h
    end

    it "returns false when the appointment is more than 48 hours away" do
      appointment = build(:appointment, starts_at: 72.hours.from_now)
      expect(appointment).not_to be_within_48h
    end

    it "returns true for past appointments within 48 hours" do
      appointment = build(:appointment, starts_at: 24.hours.ago)
      expect(appointment).to be_within_48h
    end
  end

  describe "#cancellable?" do
    it "returns true for a confirmed future appointment" do
      appointment = build(:appointment, starts_at: 1.day.from_now, status: :confirmed)
      expect(appointment).to be_cancellable
    end

    it "returns false for a past appointment" do
      appointment = build(:appointment, starts_at: 1.hour.ago, status: :confirmed)
      expect(appointment).not_to be_cancellable
    end

    it "returns false for a cancelled appointment" do
      appointment = build(:appointment, :cancelled, starts_at: 1.day.from_now)
      expect(appointment).not_to be_cancellable
    end

    it "returns false for a completed appointment" do
      appointment = build(:appointment, :completed)
      expect(appointment).not_to be_cancellable
    end

    it "returns false for a no_show appointment" do
      appointment = build(:appointment, :no_show)
      expect(appointment).not_to be_cancellable
    end
  end

  # ---------------------------------------------------------------------------
  # Financial helpers
  # ---------------------------------------------------------------------------
  describe "#refund_amount" do
    context "when cancelled more than 48 hours before the appointment" do
      it "returns the full amount paid" do
        appointment = create(:appointment, :beyond_48h)
        create(:payment, appointment: appointment, amount_cents: 10_000, deposit_cents: 2_000)
        expect(appointment.refund_amount).to eq(100.0)
      end
    end

    context "when cancelled within 48 hours of the appointment" do
      it "returns the amount minus the deposit (deposit is forfeited)" do
        appointment = create(:appointment, :within_48h)
        create(:payment, appointment: appointment, amount_cents: 10_000, deposit_cents: 2_000)
        expect(appointment.refund_amount).to eq(80.0)
      end
    end

    context "when no payment exists" do
      it "returns 0.0" do
        appointment = build(:appointment)
        expect(appointment.refund_amount).to eq(0.0)
      end
    end
  end

  describe "#amount_paid" do
    it "returns amount in dollars" do
      appointment = create(:appointment)
      create(:payment, appointment: appointment, amount_cents: 15_000)
      expect(appointment.amount_paid).to eq(150.0)
    end

    it "returns 0.0 when no payment" do
      appointment = build(:appointment)
      expect(appointment.amount_paid).to eq(0.0)
    end
  end

  describe "#deposit_paid" do
    it "returns deposit in dollars" do
      appointment = create(:appointment)
      create(:payment, appointment: appointment, deposit_cents: 3_000)
      expect(appointment.deposit_paid).to eq(30.0)
    end

    it "returns 0.0 when no payment" do
      appointment = build(:appointment)
      expect(appointment.deposit_paid).to eq(0.0)
    end
  end

  describe "#balance_due" do
    it "returns the difference between amount and deposit" do
      appointment = create(:appointment)
      create(:payment, appointment: appointment, amount_cents: 10_000, deposit_cents: 2_000)
      expect(appointment.balance_due).to eq(80.0)
    end
  end

  # ---------------------------------------------------------------------------
  # Display helpers
  # ---------------------------------------------------------------------------
  describe "#display_time" do
    it "formats the start time for display" do
      appointment = build(:appointment, starts_at: Time.zone.parse("2026-08-01 14:00:00"))
      expect(appointment.display_time).to eq("Aug 1, 2026 at 2:00 PM")
    end
  end

  describe "#time_range" do
    it "returns a formatted 60-minute window by default" do
      appointment = build(:appointment, starts_at: Time.zone.parse("2026-08-01 14:00:00"))
      expect(appointment.time_range).to eq("2:00 PM – 3:00 PM")
    end

    it "accepts a custom duration" do
      appointment = build(:appointment, starts_at: Time.zone.parse("2026-08-01 14:00:00"))
      expect(appointment.time_range(90)).to eq("2:00 PM – 3:30 PM")
    end
  end

  # ---------------------------------------------------------------------------
  # Class-level scopes
  # ---------------------------------------------------------------------------
  describe ".confirmed_upcoming" do
    it "returns confirmed appointments in the future ordered by starts_at" do
      future = create(:appointment, starts_at: 2.days.from_now, status: :confirmed)
      _past = create(:appointment, starts_at: 2.days.ago, status: :confirmed)
      _cancelled = create(:appointment, starts_at: 1.day.from_now, status: :cancelled)

      expect(Appointment.confirmed_upcoming).to eq([ future ])
    end
  end

  describe ".no_show_rate" do
    it "returns the fraction of appointments that are no_show" do
      create(:appointment, :no_show)
      create(:appointment, :completed)
      create(:appointment, :completed)

      expect(Appointment.no_show_rate).to be_within(0.001).of(1.0 / 3.0)
    end

    it "returns 0.0 when there are no appointments" do
      expect(Appointment.no_show_rate).to eq(0.0)
    end
  end

  describe ".completion_rate" do
    it "returns the fraction of appointments that are completed" do
      create(:appointment, :completed)
      create(:appointment, :completed)
      create(:appointment, :no_show)

      expect(Appointment.completion_rate).to be_within(0.001).of(2.0 / 3.0)
    end
  end

  describe ".todays_schedule" do
    it "returns appointments starting today ordered by time" do
      today_early = create(:appointment, starts_at: Time.current.beginning_of_day + 9.hours)
      today_late  = create(:appointment, starts_at: Time.current.beginning_of_day + 14.hours)
      _tomorrow   = create(:appointment, starts_at: 1.day.from_now)

      expect(Appointment.todays_schedule).to eq([ today_early, today_late ])
    end
  end

  describe ".needs_follow_up" do
    it "returns completed and no_show appointments from the last 7 days" do
      recent_completed = create(:appointment, :completed, starts_at: 2.days.ago)
      recent_no_show   = create(:appointment, :no_show,   starts_at: 3.days.ago)
      _old             = create(:appointment, :completed,  starts_at: 10.days.ago)
      _future          = create(:appointment, starts_at: 2.days.from_now)

      expect(Appointment.needs_follow_up).to contain_exactly(recent_completed, recent_no_show)
    end
  end
end
