# frozen_string_literal: true

# Caches OData that may have changed.
class CacheODataJob < ApplicationJob
  # Default to lower-priority queue.
  queue_as :odata

  def perform
    enqueued_jobs = Delayed::Job.where("handler LIKE '%job_class: CacheODataJob%'").where(failed_at: nil)
    # Wait to get called again by the scheduler if something else is already in progress.
    return if enqueued_jobs.count > 1

    responses = Response.where(dirty_json: true)
    responses.each do |response|
      CacheODataJob.cache_response(response, logger: Delayed::Worker.logger)
    end
  end

  # This can be invoked synchronously or asynchronously, depending on need.
  def self.cache_response(response, logger: Rails.logger)
    json = Results::ResponseJsonGenerator.new(response).as_json
    # Disable validation for a ~25% performance gain.
    response.update_without_validate!(cached_json: json)
    json
  rescue StandardError => e
    logger.debug(
      "Failed to update Response #{response.shortcode}\n" \
      "  Mission: #{response.mission.name}\n" \
      "  Form:    #{response.form.name}\n" \
      "  #{e.message}"
    )
    # Phone home without failing the entire operation.
    ExceptionNotifier.notify_exception(e, data: {shortcode: response.shortcode})
    {error: e.class.name}
  end
end
