class Trophy < ApplicationRecord
  belongs_to :user

  DEFINITIONS = {
    "first_post"       => { name: "First Post",        description: "Posted your first reply" },
    "posts_10"         => { name: "Getting Started",   description: "Made 10 posts" },
    "posts_100"        => { name: "Regular",           description: "Made 100 posts" },
    "posts_1000"       => { name: "Veteran",           description: "Made 1,000 posts" },
    "first_upload"     => { name: "Uploader",          description: "Uploaded your first file" },
    "uploads_10"       => { name: "Contributor",       description: "Uploaded 10 files" },
    "reputation_50"    => { name: "Respected",         description: "Reached +50 reputation" },
    "reputation_200"   => { name: "Highly Regarded",   description: "Reached +200 reputation" },
    "account_30days"   => { name: "Member",            description: "Account is 30 days old" },
    "account_1year"    => { name: "Veteran Member",    description: "Account is 1 year old" },
    "first_download"   => { name: "Downloader",        description: "Downloaded your first file" },
    "downloads_100"    => { name: "Power User",        description: "Downloaded 100 files" }
  }.freeze

  validates :slug, inclusion: { in: DEFINITIONS.keys }
  validates :slug, uniqueness: { scope: :user_id }

  scope :recent, -> { order(awarded_at: :desc) }

  def self.award!(user, slug)
    return if exists?(user: user, slug: slug)
    defn = DEFINITIONS[slug.to_s]
    return unless defn
    create!(
      user:        user,
      slug:        slug.to_s,
      name:        defn[:name],
      description: defn[:description],
      awarded_at:  Time.current
    )
  rescue ActiveRecord::RecordNotUnique
    nil
  end

  def self.check_and_award!(user)
    user_posts      = user.posts_count
    user_uploads    = Attachment.where(user_id: user.id).count
    user_rep        = user.reputation
    user_age_days   = (Time.current - user.created_at) / 1.day
    user_downloads  = DownloadHistory.where(user_id: user.id).count

    award!(user, "first_post")    if user_posts >= 1
    award!(user, "posts_10")      if user_posts >= 10
    award!(user, "posts_100")     if user_posts >= 100
    award!(user, "posts_1000")    if user_posts >= 1000
    award!(user, "first_upload")  if user_uploads >= 1
    award!(user, "uploads_10")    if user_uploads >= 10
    award!(user, "reputation_50") if user_rep >= 50
    award!(user, "reputation_200") if user_rep >= 200
    award!(user, "account_30days") if user_age_days >= 30
    award!(user, "account_1year")  if user_age_days >= 365
    award!(user, "first_download") if user_downloads >= 1
    award!(user, "downloads_100")  if user_downloads >= 100
  end
end
