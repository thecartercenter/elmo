# Actions for QingGroups
# All requests in this controller are AJAX based.
class QingGroupsController < ApplicationController

  include Parameters

  # authorization via cancan
  load_and_authorize_resource

  before_filter :prepare_qing_group, only: [:create]
  before_filter :validate_destroy, only: [:destroy]

  def new
    @form = Form.find(params[:form_id])
    # Adding group requires same permissions as removing questions.
    authorize!(:add_questions, @form)
    @qing_group = QingGroup.new(form: @form)
    render(partial: 'modal')
  end

  def edit
    @qing_group = QingGroup.find(params[:id])
    render(partial: 'modal')
  end

  def create
    # Adding group requires same permissions as removing questions.
    authorize!(:add_questions, @qing_group.form)
    @qing_group.parent = @qing_group.form.root_group
    @qing_group.save!
    render partial: 'group', locals: {qing_group: @qing_group}
  end

  def update
    @qing_group.update_attributes!(qing_group_params)
    render partial: 'group_inner', locals: {qing_group: @qing_group}
  end

  def destroy
    # Removing group requires same permissions as removing questions.
    authorize!(:remove_questions, @qing_group.form)
    @qing_group.destroy
    render nothing: true, status: 204
  end

  private

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
      translation_keys = permit_translations(params[:qing_group], :group_name, :group_hint)
      params.require(:qing_group).permit([:form_id, :repeats] + translation_keys)
    end
end
