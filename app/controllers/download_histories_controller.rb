class DownloadHistoriesController < ApplicationController
  before_action :require_login

  def index
    @histories = current_user.download_histories
                             .includes(attachment: :user)
                             .recent
                             .page(params[:page])
                             .per(30)
  end
end
