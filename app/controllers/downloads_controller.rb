class DownloadsController < ApplicationController
  before_action :require_login

  def index
    public_files = Attachment.approved.public_downloads
    @attachments = public_files.joins(:user).includes(:attachable, file_attachment: :blob)
                             .order(created_at: :desc)
    if params[:q].present?
      query = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].strip)}%"
      @attachments = @attachments.where("attachments.filename ILIKE :query OR attachments.content_type ILIKE :query OR users.username ILIKE :query", query: query)
    end
    @attachments = @attachments.page(params[:page]).per(25)
    @total_downloads = public_files.sum(:download_count)
    @total_files = public_files.count
    @total_size = public_files.sum(:byte_size)
  end
end
