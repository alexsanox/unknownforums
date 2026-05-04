class FileCommentsController < ApplicationController
  before_action :require_login
  before_action :set_attachment

  def create
    @comment = @attachment.file_comments.build(comment_params.merge(user: current_user))
    if @comment.save
      redirect_to attachment_path(@attachment), notice: "Comment posted."
    else
      redirect_to attachment_path(@attachment), alert: @comment.errors.full_messages.join(", ")
    end
  end

  def destroy
    @comment = @attachment.file_comments.find(params[:id])
    unless current_user == @comment.user || moderator_or_admin?
      return redirect_to root_path, alert: "Access denied."
    end
    @comment.update!(deleted: true)
    redirect_to attachment_path(@attachment), notice: "Comment removed."
  end

  private

  def set_attachment
    @attachment = Attachment.find(params[:attachment_id])
  end

  def comment_params
    params.require(:file_comment).permit(:body, :rating)
  end
end
