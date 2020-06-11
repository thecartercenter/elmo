# frozen_string_literal: true

module Results
  # Generates cached JSON for a given response.
  class ResponseJsonGenerator
    include ActionView::Helpers::TextHelper

    attr_accessor :response

    def initialize(response)
      self.response = response
    end

    def as_json
      object = {}
      object["ResponseID"] = response.id
      object["ResponseShortcode"] = response.shortcode
      object["FormName"] = form.name
      object["ResponseSubmitterName"] = user.name
      object["ResponseSubmitDate"] = response.created_at.iso8601
      object["ResponseReviewed"] = response.reviewed?
      root = response.root_node_including_tree(:choices, form_item: :question, option_node: :option_set)
      add_answers(root, object) unless root.nil?
      add_nil_answers(object, response)
      object
    end

    private

    delegate :form, :user, to: :response

    # Adds data for the given node to the given object. Object may be an array or hash.
    def add_answers(node, object)
      node.children.each do |child_node|
        if child_node.is_a?(Answer)
          object[child_node.question_code] = value_for(child_node)
        elsif child_node.is_a?(AnswerSet)
          object[child_node.question_code] = answer_set_value(child_node)
        elsif child_node.is_a?(AnswerGroup)
          add_group_answers(child_node, object)
        elsif child_node.is_a?(AnswerGroupSet)
          set = object[node_key(child_node)] = []
          add_answers(child_node, set)
        end
      end
    end

    def add_group_answers(group, object)
      if group.repeatable?
        object << (item = {})
        add_answers(group, item)
      else
        subgroup = object[node_key(group)] = {}
        add_answers(group, subgroup)
      end
    end

    def answer_set_value(answer_set)
      set = {}
      answer_set.children.each do |answer|
        option_node = answer.option_node
        set[option_node.level_name] = answer.option_name if option_node
      end
      set.to_s
    end

    def value_for(answer)
      case answer.qtype_name
      when "date" then answer.date_value
      when "time" then answer.time_value&.to_s(:std_time)
      when "datetime" then answer.datetime_value&.iso8601
      when "integer", "counter" then answer.value&.to_i
      when "decimal" then answer.value&.to_f
      when "select_one" then answer.option_name
      when "select_multiple" then answer.choices.empty? ? nil : answer.choices.map(&:option_name).sort.to_s
      when "location" then answer.attributes.slice("latitude", "longitude", "altitude", "accuracy").to_s
      else format_value(answer.value)
      end
    end

    def format_value(value)
      # Data that's been copied from MS Word contains a bunch of HTML decoration.
      # Get rid of that via simple_format.
      /\A<!--/.match?(value) ? simple_format(value) : value.to_s
    end

    # Make sure we include everything from the metadata in our output,
    # even if the Response didn't include that answer originally.
    def add_nil_answers(object, response)
      response.form.c.map do |c|
        object[c.code.vanilla] ||= nil
      end
    end

    # Returns the OData key for a given group, response node, or form node.
    def node_key(node)
      node.code.vanilla
    end
  end
end
