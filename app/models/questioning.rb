class Questioning < FormItem
  include Replication::Replicable

  NON_REFABLE_TYPES = %w(location image annotated_image signature sketch audio video).to_set

  delegate :all_options, :auto_increment?, :code, :code=, :first_leaf_option_node, :first_leaf_option,
    :first_level_option_nodes, :has_options?, :hint, :level_count, :level, :levels, :min_max_error_msg,
    :multilevel?, :multimedia?, :name, :numeric?, :odk_constraint, :odk_name, :option_set_id,
    :option_set_id=, :option_set, :option_set=, :options, :preordered_option_nodes, :printable?,
    :qtype_name, :qtype_name=, :qtype, :select_options, :sms_formatting_as_appendix?,
    :sms_formatting_as_text?, :standardized?, :subqings, :tags, :temporal?, :title, :metadata_type,
    to: :question
  delegate :published?, to: :form
  delegate :smsable?, to: :form, prefix: true
  delegate :group_name, to: :parent, prefix: true, allow_nil: true

  scope :visible, -> { where(hidden: false) }

  accepts_nested_attributes_for :question

  # remove heirarchy of objects
  def self.terminate_sub_relationships(questioning_ids)
    answers = Answer.where(questioning_id: questioning_ids)
    Choice.where(answer_id: answers).delete_all
    answers.destroy_all
  end

  # checks if this form has any answers
  # uses the form.qing_answer_count method because these requests tend to come in batches so better
  # to fetch the counts for all qings on the form at once
  def has_answers?
    form.qing_answer_count(self) > 0
  end

  def conditions_changed?
    display_conditions.any?(&:changed?) || display_conditions.any?(&:new_record?)
  end

  def subqings
    @subqings ||= if multilevel?
      levels.each_with_index.map { |l, i| Subqing.new(questioning: self, level: l, rank: i + 1) }
    else
      [Subqing.new(questioning: self, rank: 1)]
    end
  end

  def core_changed?
    (changed & %w(required hidden default)).any? || conditions_changed?
  end

  # Checks if this Questioning is in a repeat group.
  def repeatable?
    # Questions can only be repeatable if they're in a group, which they can't be if they're level 1.
    ancestry_depth > 1 && parent.repeatable?
  end

  # all questionings that can be referred to by a condition
  def refable_qings
    previous.reject { |qing| NON_REFABLE_TYPES.include?(qing.qtype_name) }
  end

  # Gets full dotted ranks of all referring conditions' questionings.
  def referring_condition_ranks
    referring_conditions.map { |c| c.questioning.full_dotted_rank }
  end

  # Returns any questionings appearing before this one on the form.
  # For an unsaved questioning, returns all questions on form.
  # If an unsaved question does not have a form defined, this will result in an error.
  def previous
    return form.questionings if new_record?
    form.questionings.reject { |q| q == self || (q.full_rank <=> full_rank) == 1 }
  end

  def smsable?
    visible? && qtype.smsable?
  end

  # Duck type
  def fragment?
    false
  end

  def qid
    question.id
  end

  # REFACTOR: should use translation delegation, from abandoned std_objs branch
  def method_missing(*args)
    # pass appropriate methods on to question
    if is_question_method?(args[0].to_s)
      question.send(*args)
    else
      super
    end
  end

  def respond_to?(symbol, *)
    is_question_method?(symbol.to_s) || super
  end

  def respond_to_missing?(symbol, include_private)
    is_question_method?(symbol.to_s) || super
  end

  def is_question_method?(symbol)
    symbol.match(/\A((name|hint)_([a-z]{2})(=?))(_before_type_cast)?\z/)
  end
  # /REFACTOR

  private

  def normalize
    super
    if question.metadata_type.present?
      self.hidden = true
      display_conditions.destroy_all
    end
    self.required = false if hidden? || read_only?
    true
  end
end
