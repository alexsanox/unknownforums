class DownloadHistory < ApplicationRecord
  belongs_to :user
  belongs_to :attachment

  scope :recent, -> { order(created_at: :desc) }
end
