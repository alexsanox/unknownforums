class FileTagsController < ApplicationController
  before_action :require_login
  before_action :set_attachment

  def create
    unless moderator_or_admin? || current_user == @attachment.user
      return redirect_to attachment_path(@attachment), alert: "Access denied."
    end
    tag = @attachment.file_tags.build(tag: params.dig(:file_tag, :tag).to_s.strip.downcase.gsub(/\s+/, "-"))
    if tag.save
      redirect_to attachment_path(@attachment), notice: "Tag added."
    else
      redirect_to attachment_path(@attachment), alert: tag.errors.full_messages.join(", ")
    end
  end

  def destroy
    unless moderator_or_admin? || current_user == @attachment.user
      return redirect_to attachment_path(@attachment), alert: "Access denied."
    end
    @attachment.file_tags.find(params[:id]).destroy
    redirect_to attachment_path(@attachment), notice: "Tag removed."
  end

  private

  def set_attachment
    @attachment = Attachment.find(params[:attachment_id])
  end
end
