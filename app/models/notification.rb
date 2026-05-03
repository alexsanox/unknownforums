class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"
  belongs_to :actor,     class_name: "User"
  belongs_to :notifiable, polymorphic: true, optional: true

  KINDS = %w[mention subscription reaction].freeze

  validates :kind, inclusion: { in: KINDS }

  scope :unread,  -> { where(read: false) }
  scope :recent,  -> { order(created_at: :desc) }

  after_create :bust_recipient_cache

  private

  def bust_recipient_cache
    recipient&.bust_notification_cache
  end

  public

  def self.notify!(recipient:, actor:, kind:, notifiable: nil, message: nil)
    return if recipient == actor
    create!(
      recipient:       recipient,
      actor:           actor,
      kind:            kind,
      notifiable:      notifiable,
      message:         message
    )
  rescue ActiveRecord::RecordNotUnique
    # already notified, ignore
  end

  def mark_read!
    update_column(:read, true)
  end
end
