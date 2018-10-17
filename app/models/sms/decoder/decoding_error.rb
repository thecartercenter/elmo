# frozen_string_literal: true

module Sms
  module Decoder
    # models an error generated by the sms decoding system
    class DecodingError < Sms::GenericError
      attr_reader :type, :params

      def initialize(type, params = {})
        super(type)
        @type = type
        @params = params
      end

      def to_s
        super + " #{@params.inspect}"
      end
    end
  end
end
