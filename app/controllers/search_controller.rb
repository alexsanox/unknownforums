class SearchController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    return if @query.length < 2

    tsquery = @query.split.map { |w| ActiveRecord::Base.connection.quote("#{w}:*") }.join(" & ")

    @threads = ForumThread.joins(:user)
                          .where("forum_threads.search_vector @@ to_tsquery('english', #{ActiveRecord::Base.connection.quote(tsquery)})")
                          .select("forum_threads.*, ts_rank(forum_threads.search_vector, to_tsquery('english', #{ActiveRecord::Base.connection.quote(tsquery)})) AS rank")
                          .order("rank DESC")
                          .limit(20)

    @posts = Post.visible
                 .joins(:user, :thread)
                 .where("posts.search_vector @@ to_tsquery('english', #{ActiveRecord::Base.connection.quote(tsquery)})")
                 .select("posts.*, ts_rank(posts.search_vector, to_tsquery('english', #{ActiveRecord::Base.connection.quote(tsquery)})) AS rank")
                 .includes(:user, :thread)
                 .order("rank DESC")
                 .limit(20)
  end
end
