class MissionsController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource

  def index
  end

  def new
    render(:form)
  end

  def show
    render(:form)
  end

  def edit
    render(:form)
  end

  def create
    begin
      @mission.save!
      set_success_and_redirect(@mission)
    rescue ActiveRecord::RecordInvalid
      flash.now[:error] = I18n.t('activerecord.errors.models.mission.general')
      render(:form)
    end
  end

  def update
    begin
      @mission.update_attributes!(params[:mission])
      set_success_and_redirect(@mission)
    rescue ActiveRecord::RecordInvalid
      render(:form)
    end
  end

  def destroy
    destroy_and_handle_errors(@mission)
    redirect_to(index_url_with_page_num)
  end
end
