class FileComment < ApplicationRecord
  belongs_to :attachment
  belongs_to :user

  validates :body, presence: true, length: { minimum: 2, maximum: 1000 }
  validates :rating, inclusion: { in: 1..5 }, allow_nil: true

  scope :visible, -> { where(deleted: false) }
  scope :recent,  -> { order(created_at: :desc) }
end
