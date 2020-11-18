# frozen_string_literal: true

# Represents the name of one level of an option set (e.g. 'Country', 'State', or 'City')
class OptionLevel
  # TODO
  # include ActiveModel::Serializers::JSON
  include ActiveModel::Model
  include Translatable

  MAX_NAME_LENGTH = 20

  attr_accessor :option_set

  translates :name

  # For serialization.
  def attributes
    %w[name name_translations].map_hash { |a| send(a) }
  end

  def as_json(_options = {})
    super(root: false)
  end
end
