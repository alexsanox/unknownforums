class LeaderboardsController < ApplicationController
  def index
    @top_posters = User.order(posts_count: :desc, created_at: :asc).limit(10)
    @top_reputation = User.order(reputation: :desc, posts_count: :desc).limit(10)
    @top_uploaders = top_uploaders
    @top_downloaders = top_downloaders
    @top_files = Attachment.public_downloads.approved.includes(:user).top_downloads.limit(10)
  end

  private

  def top_uploaders
    counts = Attachment.group(:user_id).count.sort_by { |_user_id, count| -count }.first(10)
    users = User.where(id: counts.map(&:first)).index_by(&:id)
    counts.filter_map { |user_id, count| [users[user_id], count] if users[user_id] }
  end

  def top_downloaders
    counts = Attachment.group(:user_id).sum(:download_count).sort_by { |_user_id, count| -count }.first(10)
    users = User.where(id: counts.map(&:first)).index_by(&:id)
    counts.filter_map { |user_id, count| [users[user_id], count] if users[user_id] }
  end
end
