class FileTag < ApplicationRecord
  belongs_to :attachment

  validates :tag, presence: true,
                  length: { minimum: 2, maximum: 30 },
                  format: { with: /\A[a-z0-9\-]+\z/, message: "only lowercase letters, numbers, hyphens" },
                  uniqueness: { scope: :attachment_id }

  before_validation { self.tag = tag.to_s.strip.downcase.gsub(/\s+/, "-") }
end
