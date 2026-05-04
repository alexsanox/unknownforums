class IpBan < ApplicationRecord
  belongs_to :banned_by, class_name: "User", optional: true

  validates :ip_address, presence: true, uniqueness: true

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }

  def self.banned?(ip)
    active.exists?(ip_address: ip.to_s)
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end
end
