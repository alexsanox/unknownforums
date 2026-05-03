class PostReactionsController < ApplicationController
  before_action :require_login

  def create
    post   = Post.find(params[:post_id])
    emoji  = params[:emoji]

    unless PostReaction::EMOJIS.include?(emoji)
      return redirect_back(fallback_location: root_path, alert: "Invalid reaction.")
    end

    reaction = PostReaction.find_or_initialize_by(post: post, user: current_user, emoji: emoji)
    if reaction.persisted?
      reaction.destroy
    else
      reaction.save
    end

    if request.xhr? || request.format.turbo_stream?
      @post = post.reload
      render turbo_stream: turbo_stream.replace(
        "reactions-#{post.id}",
        partial: "posts/reactions",
        locals: { post: @post }
      )
    else
      redirect_back fallback_location: root_path
    end
  end
end
