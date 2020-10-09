# frozen_string_literal: true

class WelcomeController < ApplicationController
  include ReportEmbeddable
  include ResponseIndexable

  # Don't need to authorize since we manually redirect to login if no user.
  # This is because anybody is 'allowed' to see the root and letting the auth system handle things
  # leads to nasty messages and weird behavior. We merely redirect because otherwise the page would be blank
  # and not very interesting.
  # We also skip the check for unauthorized because who cares if someone sees it.
  skip_authorization_check only: %i[index unauthorized]

  # number of rows in the stats blocks
  STAT_ROWS = 3

  # shows a series of blocks with info about the app
  def index
    return redirect_to(login_path) unless current_user

    if current_mission
      # Dashboard has no title.
      @dont_print_title = true
      dashboard_index
    elsif admin_mode?
      render(:admin)
    else
      render(:no_mission)
    end
  end

  # map info window
  def info_window
    @response = Response.with_basic_assoc.find(params[:response_id])
    authorize!(:read, @response)
    render(layout: false)
  end

  def unauthorized
  end

  private

  def dashboard_index
    accessible_responses = Response.accessible_by(current_ability)

    instance_variable_cache("@responses") do
      accessible_responses.with_basic_assoc.with_basic_answers.latest_first.paginate(page: 1, per_page: 20)
    end

    instance_variable_cache("@total_response_count") do
      accessible_responses.count
    end

    instance_variable_cache("@unreviewed_response_count") do
      accessible_responses.unreviewed.count
    end

    location_answers = Answer.location_answers_for_mission(current_mission, current_user)
    instance_variable_cache("@location_answers") do
      location_answers.pluck(:response_id, :latitude, :longitude)
    end
    instance_variable_cache("@location_answers_count") do
      location_answers.total_entries
    end

    instance_variable_cache("@responses_by_form") do
      Response.per_form(accessible_responses, STAT_ROWS)
    end

    instance_variable_cache("@responses_per_user", dependencies: %i[responses assignments]) do
      User.sorted_enumerator_response_counts(current_mission, STAT_ROWS)
    end

    instance_variable_cache("@recent_response_count", expires_in: 30.minutes) do
      Response.recent_count(Response.accessible_by(current_ability))
    end

    # get list of all reports for the mission, for the dropdown
    @reports = Report::Report.accessible_by(current_ability).by_name

    prepare_report

    # render JSON if ajax request
    if request.xhr?
      data = {
        recent_responses: render_to_string(partial: "recent_responses"),
        response_locations: {
          answers: @location_answers,
          count: @location_answers_count
        },
        report_stats: render_to_string(partial: "report_stats")
      }
      render(json: data)
    else
      render(:dashboard)
    end
  end

  # Yields to a block and caches the result and stores in an ivar with the given `name`.
  # Computes a cache key based on given dependencies (looked up in `cache_keys`) and on `name`.
  def instance_variable_cache(name, dependencies: %i[responses enumerator_id], **options)
    key = dependencies.map { |d| cache_keys.fetch(d) } << name
    instance_variable_set(name, Rails.cache.fetch(key, **options) { yield })
  end

  def cache_keys
    @cache_keys ||= {
      responses: Response.per_mission_cache_key(current_mission),

      # We use assignments instead of users because
      # if a user gets removed or added to the mission, or role changes, that should show up
      # but we don't include users in the cache key since users get updated every request
      # and that would defeat the purpose.
      assignments: Assignment.per_mission_cache_key(current_mission),

      # If the user is an enumerator, include their ID. If they are staffer, coordinator, etc.,
      # return nil. This means all users of other roles will all hit the same cache.
      enumerator_id: current_user.role(current_mission) == "enumerator" ? current_user.id : nil
    }
  end

  def prepare_report
    # if report id given, load that else use most popular
    @report = if params[:report_id].present?
                Report::Report.find(params[:report_id])
              else
                Report::Report.accessible_by(current_ability).by_popularity.first
              end

    if @report
      # Make sure no funny business!
      authorize!(:read, @report)

      # We don't run the report, that will happen on an ajax call.
      build_report_data(read_only: true, embedded_mode: true)
    end
  end
end
