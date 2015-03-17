# Actions for QingGroups
# All requests in this controller are AJAX based.
class QingGroupsController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource

  before_filter :prepare_qing_group, only: [:create]
  before_filter :validate_destroy, only: [:destroy]

  def edit
    @qing_group = QingGroup.find(params[:id])
    render(partial: 'modal')
  end

  def create
    create_or_update
  end

  def update
    @qing_group.assign_attributes(qing_group_params)
    create_or_update
  end

  def destroy
    begin
      @qing_group.destroy
      render nothing: true, status: 204
    end
  end

  private
    # creates/updates the qing_group
    def create_or_update
      if @qing_group.save
        render(partial: 'form')
      else
        render(:form)
      end
    end

    def validate_destroy
      if @qing_group.children.size > 0
        return render json: [], status: 404
      end
    end

    # prepares qing_group
    def prepare_qing_group
      attrs = qing_group_params
      attrs[:ancestry] = Form.find(attrs[:form_id]).root_id
      @qing_group = QingGroup.accessible_by(current_ability).new(attrs)
      @qing_group.mission = current_mission
    end

    def qing_group_params
      params.require(:qing_group).permit(:form_id).tap do |whitelisted|
        # handle dynamic hash keys for translations
        whitelisted[:group_name_translations] = params[:qing_group][:group_name_translations]
      end
    end
end
