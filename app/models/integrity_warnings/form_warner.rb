# frozen_string_literal: true

module IntegrityWarnings
  # Enumerates integrity warnings for Forms
  class FormWarner
    attr_accessor :object

    def initialize(object)
      self.object = object
    end

    # See IntegrityWarnings::Builder#text for more info on the expected return value here.
    def careful_with_changes
      warnings = []
      warnings << :published if object.published?
      warnings
    end

    # See IntegrityWarnings::Builder#text for more info on the expected return value here.
    def features_disabled
      warnings = []
      warnings << :published if object.published?
      warnings << :has_data if object.responses.any?
      warnings
    end
  end
end
