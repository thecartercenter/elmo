class Report::Calculation < ActiveRecord::Base
  TYPES = %w(identity zero_nonzero)

  attr_writer :table_prefix

  belongs_to(:report, :class_name => "Report::Report", :foreign_key => "report_report_id", :inverse_of => :calculations)
  belongs_to(:question1, :class_name => "Question", :inverse_of => :calculations)

  before_save(:normalize_values)

  after_destroy { report.calculation_destroyed }

  # HACK TO GET STI TO WORK WITH ACCEPTS_NESTED_ATTRIBUTES_FOR
  class << self
    def new_with_cast(*a, &b)
      if (h = a.first).is_a? Hash and (type = h[:type] || h['type']) and (klass = type.constantize) != self
        raise "wtF hax!!"  unless klass < self  # klass should be a descendant of us
        return klass.new(*a, &b)
      end

      new_without_cast(*a, &b)
    end
    alias_method_chain :new, :cast
  end

  # Called when related Question is destroyed.
  def question_destroyed
    delete # Calculation makes no sense now. We use delete b/c we handle callbacks manually.
    report.calculation_destroyed(source: :question) # Report needs to know.
  end

  def as_json(options = {})
    Hash[*%w(id type attrib1_name question1_id rank).collect{|k| [k, self.send(k)]}.flatten]
  end

  def arg1
    (a1 = answer1) ? a1 : attrib1
  end

  def attrib1
    key = self.attrib1_name
    return key ? Report::AttribField.new(key) : nil
  end

  def answer1
    @answer1 ||= question1 ? Report::AnswerField.new(question1) : nil
  end

  def arg1=(arg)
    if arg.is_a?(Report::AnswerField)
      self.answer1 = arg
    else
      self.attrib1 = arg
    end
  end

  def answer1=(answer)
    self.question1_id = answer.question.id
  end

  def attrib1=(attrib)
    self.attrib1_name = attrib.name
  end

  def header_title
    attrib1 ? attrib1.title : question_label
  end

  def question_label
    report.question_labels == "title" ? question1.name : question1.code
  end

  def table_prefix
    @table_prefix.blank? ? "" : (@table_prefix + "_")
  end

  def select_expressions
    [name_expr, value_expr, sort_expr, data_type_expr]
  end

  private
    def normalize_values
      self.attrib1_name = nil if self.attrib1_name.blank?
    end
end
