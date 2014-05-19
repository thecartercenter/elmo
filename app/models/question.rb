# a question on a form
# question is a subtype of Questionable as per composite design pattern, since it may have Subquestions
class Question < Questionable
  include FormVersionable, Translatable

  CODE_FORMAT = "[a-z][a-z0-9]{1,19}"

  belongs_to(:option_set, :include => :options, :inverse_of => :questions, :autosave => true)
  has_many(:questionings, :dependent => :destroy, :autosave => true, :inverse_of => :question)
  has_many(:answers, :through => :questionings)
  has_many(:referring_conditions, :through => :questionings)
  has_many(:forms, :through => :questionings)
  has_many(:calculations, :foreign_key => 'question1_id', :inverse_of => :question1)
  has_many(:subquestions, :foreign_key => 'parent_id', :include => :option_level, :order => 'option_levels.rank',
    :inverse_of => :question, :autosave => true, :dependent => :destroy)

  before_validation(:normalize_fields)
  before_validation(:maintain_subquestions)

  validates(:code, :presence => true)
  validates(:code, :format => {:with => /^#{CODE_FORMAT}$/i}, :if => Proc.new{|q| !q.code.blank?})
  validates(:qtype_name, :presence => true)
  validates(:option_set, :presence => true, :if => Proc.new{|q| q.qtype && q.has_options?})
  validate(:code_unique_per_mission)

  scope(:by_code, order('questionables.code'))
  scope(:default_order, by_code)
  scope(:select_types, where(:qtype_name => %w(select_one select_multiple)))
  scope(:with_forms, includes(:forms))

  # fetches association counts along with the questions
  # accounts for copies with standard questions
  # - form_published returns 1 if any associated forms are published, 0 or nil otherwise
  # - standard_copy_form_id returns a std copy form id associated with the question if available, or nil if there are none
  scope(:with_assoc_counts, select(%{
      questionables.*,
      COUNT(DISTINCT answers.id) AS answer_count_col,
      COUNT(DISTINCT forms.id) AS form_count_col,
      MAX(DISTINCT forms.published) AS form_published,
      COUNT(DISTINCT copy_answers.id) AS copy_answer_count_col,
      MAX(DISTINCT copy_forms.published) AS copy_form_published,
      MAX(DISTINCT forms.standard_id) AS standard_copy_form_id
    }).joins(%{
      LEFT OUTER JOIN questionings ON questionings.question_id = questionables.id AND questionables.type = 'Question'
      LEFT OUTER JOIN forms ON forms.id = questionings.form_id
      LEFT OUTER JOIN answers ON answers.questioning_id = questionings.id
      LEFT OUTER JOIN questionables copies ON questionables.is_standard = 1 AND questionables.id = copies.standard_id
      LEFT OUTER JOIN questionings copy_questionings ON copy_questionings.question_id = copies.id
      LEFT OUTER JOIN forms copy_forms ON copy_forms.id = copy_questionings.form_id
      LEFT OUTER JOIN answers copy_answers ON copy_answers.questioning_id = copy_questionings.id
    }).group('questionables.id'))

  translates :name, :hint

  delegate :smsable?, :has_options?, :to => :qtype
  delegate :options, :geographic?, :to => :option_set, :allow_nil => true

  replicable :child_assocs => [:option_set, :subquestions], :parent_assoc => :questioning,
    :uniqueness => {:field => :code, :style => :camel_case}, :dont_copy => :key,
    :user_modifiable => [:name_translations, :_name, :hint_translations, :_hint]

  # returns questions that do NOT already appear in the given form
  def self.not_in_form(form)
    scoped.where("(questionables.id not in (select question_id from questionings where form_id='#{form.id}'))")
  end

  # returns N questions marked as key questions, sorted by the number of forms they appear in
  def self.key(n)
    where(:key => true).all.sort_by{|q| q.questionings.size}[0...n]
  end

  # returns the question type object associated with this question
  def qtype
    QuestionType[qtype_name]
  end

  def select_options
    (opt = options) ? opt.collect{|o| [o.name, o.id]} : []
  end

  # gets the number of forms which with this question is directly associated.
  # uses the form_count/std_form_count eager loaded fields if available
  def form_count
    respond_to?(:form_count_col) ? form_count_col : forms.count
  end

  # gets the number of answers to this question. uses an eager loaded col if available
  def answer_count
    if is_standard?
      respond_to?(:copy_answer_count_col) ? copy_answer_count_col : copies.inject(0){|sum,c| sum += c.answer_count}
    else
      respond_to?(:answer_count_col) ? answer_count_col : answers.count
    end
  end

  # determins if question has answers
  # uses the eager-loaded answer_count field if available
  def has_answers?
    answer_count > 0
  end

  # determines if the question appears on any published forms
  # uses the eager-loaded form_published field if available
  def published?
    if is_standard?
      respond_to?(:copy_form_published_col) ? copy_form_published_col == 1 : copies.any?(&:published?)
    else
      respond_to?(:form_published_col) ? form_published_col == 1 : forms.any?(&:published?)
    end
  end

  # determines if any of the forms on which this question appears are standard copies
  # uses a special eager-loaded attribute if available
  def has_standard_copy_form?
    is_standard ? false : respond_to?(:standard_copy_form_id) ? !standard_copy_form_id.nil? : forms.any?(&:standard_copy?)
  end

  # checks if any associated forms are smsable
  # NOTE different from plain Question.smsable?
  def form_smsable?
    forms.any?(&:smsable?)
  end

  # an odk-friendly unique code
  def odk_code
    "q#{id}"
  end

  # an odk (xpath) expression of any question contraints
  def odk_constraint
    exps = []
    exps << ". #{minstrictly ? '>' : '>='} #{casted_minimum}" if minimum
    exps << ". #{maxstrictly ? '<' : '<='} #{casted_maximum}" if maximum
    exps.empty? ? nil : "(" + exps.join(" and ") + ")"
  end

  # shortcut method for tests
  def qing_ids
    questionings.collect{|qing| qing.id}
  end

  # convert value stored as decimal to integer if integer question type
  def casted_minimum
    minimum.blank? ? nil : (qtype_name == 'decimal' ? minimum : minimum.to_i)
  end

  def casted_maximum
    maximum.blank? ? nil : (qtype_name == 'decimal' ? maximum : maximum.to_i)
  end

  def casted_minimum=(m)
    self.minimum = m
    self.minimum = casted_minimum
  end

  def casted_maximum=(m)
    self.maximum = m
    self.maximum = casted_maximum
  end

  def min_max_error_msg
    return nil unless minimum || maximum
    clauses = []
    clauses << I18n.t("question.maxmin.gt") + " " + (minstrictly ? "" : I18n.t("question.maxmin.or_eq") + " " ) + casted_minimum.to_s if minimum
    clauses << I18n.t("question.maxmin.lt") + " " + (maxstrictly ? "" : I18n.t("question.maxmin.or_eq") + " " ) + casted_maximum.to_s if maximum
    I18n.t("layout.must_be") + " " + clauses.join(" " + I18n.t("common.and") + " ")
  end

  # returns sorted list of form ids related to this form
  def form_ids
    forms.collect{|f| f.id}.sort
  end

  # gets a comma separated list of all related forms names
  def form_names
    forms.map(&:name).join(', ')
  end

  def constraint_changed?
    %w(minimum maximum minstrictly maxstrictly).any?{|f| send("#{f}_changed?")}
  end

  # checks if any core fields (type, option set, constraints) changed
  def core_changed?
    qtype_name_changed? || option_set_id_changed? || constraint_changed?
  end

  # shortcut accessor
  def option_levels
    option_set.present? ? option_set.option_levels : []
  end

  # called by an associated OptionSet when its OptionLevels change
  def option_levels_changed
    # first reload the association in case it's stale
    option_set(true)

    maintain_subquestions
    save!
  end

  private

    def code_unique_per_mission
      errors.add(:code, :taken) unless unique_in_mission?(:code)
    end

    def normalize_fields
      # clear whitespace from code
      self.code = code.strip

      normalize_constraint_values

      return true
    end

    # normalizes constraints based on question type
    def normalize_constraint_values
      # constraint should be nil/non-nil depending on qtype
      if qtype.numeric?
        # for numeric qtype, min/max can still be nil, and booleans should be nil if min/max are nil, else should be false
        self.minstrictly = false if !minimum.nil? && minstrictly.nil?
        self.maxstrictly = false if !maximum.nil? && maxstrictly.nil?
        self.minstrictly = nil if minimum.nil?
        self.maxstrictly = nil if maximum.nil?
      else
        # for non-numeric qtype, all constraint fields should be nil
        self.minimum = nil
        self.maximum = nil
        self.minstrictly = nil
        self.maxstrictly = nil
      end
    end

    # ensures Subquestion objects are created/destroyed to match the current OptionSet, if any
    def maintain_subquestions
      # add subquestions for any missing option levels
      (option_levels - subquestions.map(&:option_level)).each do |ol|
        subquestions.build(:option_level => ol)
      end

      # remove any obsolete subquestions (all subquestions with option levels NOT IN the current set)
      subquestions.reject{|subq| option_levels.include?(subq.option_level)}.each do |subq|
        subquestions.destroy(subq)
      end

      # re-sort by OptionLevel rank
      subquestions.sort_by(&:rank)

      return true
    end
end
