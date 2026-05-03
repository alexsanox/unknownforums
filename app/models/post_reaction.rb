class PostReaction < ApplicationRecord
  EMOJIS = %w[👍 🔥 😂 ❤️ 👎].freeze

  belongs_to :post
  belongs_to :user

  validates :emoji, inclusion: { in: EMOJIS, message: "is not allowed" }
  validates :user_id, uniqueness: { scope: [:post_id, :emoji], message: "already reacted" }
end
