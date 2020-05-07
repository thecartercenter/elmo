# frozen_string_literal: true

module OData
  class SimpleEntity
    attr_reader :name, :plural_name, :qualified_name, :key_property, :properties, :navigation_properties,
      :extra_tags

    # Property types are defined in odata_server's
    # `Property.column_adapter_return_types` static variable.
    #
    # TODO: Not all of these should be rendered as EntitySets (bottom of $metadata),
    #   e.g. repeat groups should be excluded. This may not affect Power BI.
    def initialize(name, key_name: nil, property_types: {}, extra_tags: {})
      @name = name
      @plural_name = name
      @qualified_name = "#{ODataController::NAMESPACE}.#{name}"
      @key_property = key_name ? SimpleProperty.new(name: key_name) : nil
      @properties = property_types.transform_values { |type| SimpleProperty.new(return_type: type) }
      @navigation_properties = []
      @extra_tags = extra_tags
    end
  end
end