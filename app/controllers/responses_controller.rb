class ResponsesController < ApplicationController
  # need to load with associations for show and edit
  before_filter :load_with_associations, :only => [:show, :edit]
  before_filter :mark_response_as_checked_out, :only => [:edit]

  # authorization via CanCan
  load_and_authorize_resource

  def index
    # handle different formats
    respond_to do |format|
      # html is the normal index page
      format.html do
        # apply search and pagination
        params[:page] ||= 1

        # paginate
        @responses = @responses.paginate(:page => params[:page], :per_page => 20)

        # include answers so we can show key questions
        @responses = @responses.includes(:answers)

        # do search, including excerpts, if applicable
        if params[:search].present?
          begin
            @responses = Response.do_search(@responses, params[:search], {:mission => current_mission}, :include_excerpts => true)
          rescue Search::ParseError
            flash.now[:error] = "#{t('search.search_error')}: #{$!}"
          rescue ThinkingSphinx::SphinxError
            # format sphinx message a little more nicely
            sphinx_msg = $!.to_s.gsub(/index .+?:\s+/, '')
            flash.now[:error] = "#{t('search.search_error')}: #{sphinx_msg}"
          end
        end

        # render just the table if this is an ajax request
        render(:partial => "table_only", :locals => {:responses => @responses}) if ajax_request?
      end

      # csv output is for exporting responses
      format.csv do
        # do search, excluding excerpts
        if params[:search].present?
          begin
            @responses = Response.do_search(@responses, params[:search], {:mission => current_mission}, :include_excerpts => false)
          rescue Search::ParseError
            flash.now[:error] = "#{t('search.search_error')}: #{$!}"
            return
          end
        end

        # get the response, for export, but not paginated
        @responses = Response.for_export(@responses)

        # render the csv
        render_csv("elmo-#{current_mission.compact_name}-responses-#{Time.zone.now.to_s(:filename_datetime)}")
      end
    end
  end

  def show
    # if there is a search param, we try to load the response via the do_search mechanism so that we get highlighted excerpts
    if params[:search]
      # we pass a relation matching only one respoonse, so there should be at most one match
      matches = Response.do_search(Response.where(:id => @response.id), params[:search], {:mission => current_mission},
        :include_excerpts => true, :dont_truncate_excerpts => true)

      # if we get a match, then we use that object instead, since it contains excerpts
      @response = matches.first if matches.first
    end
    prepare_and_render_form
  end

  def new
    # get the form specified in the params and error if it's not there
    begin
      @response.form = Form.with_questionings.find(params[:form_id])
    rescue ActiveRecord::RecordNotFound
      # this should not be possible
      flash[:error] = "no form selected"
      return redirect_to(index_url_with_page_num)
    end

    # render the form template
    prepare_and_render_form
  end

  def edit
    flash.now[:notice] = "#{t("response.checked_out")} #{@response.checked_out_by_name}" if @response.checked_out_by_others?(current_user)
    prepare_and_render_form
  end

  def create
    # if this is a submission from ODK collect
    if request.format == Mime::XML

      # if the method is HEAD or GET just render the 'no content' status since that's what odk wants!
      if %w(HEAD GET).include?(request.method)
        render(:nothing => true, :status => 204)

      # otherwise, we should process the xml submission
      elsif upfile = params[:xml_submission_file]
        begin
          contents = upfile.read

          # set the user_id to current user
          @response.user_id = current_user.id

          # parse the xml stuff
          @response.populate_from_xml(contents)

          # ensure response's user can submit to the form
          authorize!(:submit_to, @response.form)

          # save without validating, as we have no way to present validation errors to user, and ODK already does validation
          @response.save(:validate => false)

          # ODK wants a blank response with code 201 on success
          render(:nothing => true, :status => 201)

        rescue CanCan::AccessDenied
          # permission error should give unauthorized (401)
          render(:nothing => true, :status => 401)

        rescue ActiveRecord::RecordNotFound
          # not found error should give not found (404)
          render(:nothing => true, :status => 404)

        rescue FormVersionError
          # form version outdated should give 426 (upgrade needed)
          render(:nothing => true, :status => 426)

        rescue ArgumentError
          # argument error should give unprocessible entity
          render(:nothing => true, :status => 422)

        rescue
          # if we get this far it's some kind of server error
          render(:nothing => true, :status => 500)
        end
      end

    # for HTML format just use the method below
    else
      web_create_or_update
    end
  end

  def update
    @response.assign_attributes(params[:response])
    web_create_or_update
  end

  def destroy
    destroy_and_handle_errors(@response)
    redirect_to(index_url_with_page_num)
  end

  private
    # loads the response with its associations
    def load_with_associations
      @response = Response.with_associations.find(params[:id])
    end

    # when editing a response, set timestamp to show it is being worked on
    def mark_response_as_checked_out
      @response.check_out!(current_user)
    end

    # handles creating/updating for the web form
    def web_create_or_update
      # set source/modifier to web
      @response.source = "web" if params[:action] == "create"
      @response.modifier = "web"

      # check for "update and mark as reviewed"
      @response.reviewed = true if params[:commit_and_mark_reviewed]

      if params[:action] == "update"
        @response.check_in
      end

      # try to save
      begin
        @response.save!
        set_success_and_redirect(@response)
      rescue ActiveRecord::RecordInvalid
        flash.now[:error] = I18n.t('activerecord.errors.models.response.general')
        prepare_and_render_form
      end
    end

    # prepares objects for and renders the form template
    def prepare_and_render_form
      # get the users to which this response can be assigned
      # which is the users in this mission plus admins
      # (we need to include admins because they can submit forms to any mission)
      @possible_submitters = User.assigned_to_or_admin(current_mission).by_name

      # render the form
      render(:form)
    end
end
