# frozen_string_literal: true

# Operation for exporting response CSV.
class ResponseCSVExportOperationJob < OperationJob
  def perform(operation, search: nil, options: {})
    ability = Ability.new(user: operation.creator, mission: mission)
    result = generate_csv(responses(ability, search), options: options&.symbolize_keys)
    operation_succeeded(result)
  rescue Search::ParseError => error
    operation_failed(error.to_s)
  end

  private

  def responses(ability, search)
    responses = Response.accessible_by(ability, :export)
    responses = apply_search_scope(responses, search, mission) if search.present?

    # Get the response, for export, but not paginated.
    # We deliberately don't eager load as that is handled in the Results::CSV::Generator class.
    responses.order(:created_at)
  end

  def apply_search_scope(responses, search, mission)
    ResponsesSearcher.new(relation: responses, query: search, scope: {mission: mission}).apply
  end

  def generate_csv(responses, options:)
    attachment = Results::CSV::Generator.new(responses, options: options).export
    timestamp = Time.current.to_s(:filename_datetime)
    attachment_download_name = "#{mission.compact_name}-responses-#{timestamp}.csv"
    {
      attachment: attachment,
      # Metadata for disk storage.
      attachment_download_name: attachment_download_name,
      # Metadata for cloud storage.
      attachment_file_name: attachment_download_name,
      attachment_content_type: "text/csv"
    }
  end
end
