class Answer < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper

  belongs_to(:questioning, :inverse_of => :answers)
  belongs_to(:option, :inverse_of => :answers)
  belongs_to(:response, :inverse_of => :answers, :touch => true)
  has_many(:choices, :dependent => :destroy, :inverse_of => :answer, :autosave => true)

  before_validation(:clean_locations)
  before_save(:replicate_location_values)
  before_save(:round_ints)
  before_save(:blanks_to_nulls)

  # Remove unchecked choices before saving.
  before_save do
    choices.destroy(*choices.reject(&:checked?))
  end

  validates(:value, :numericality => true, :if => ->(a){ a.should_validate?(:numericality) })

  # in these custom validations, we add errors to the base, but we don't use full sentences (e.g. we use 'is required')
  # since this class really just represents one value
  validate(:min_max, :if => ->(a){ a.should_validate?(:min_max) })
  validate(:required, :if => ->(a){ a.should_validate?(:required) })

  accepts_nested_attributes_for(:choices)

  delegate :question, :qtype, :required?, :hidden?, :option_set, :options, :condition, :to => :questioning
  delegate :name, :hint, :to => :question, :prefix => true
  delegate :name, to: :level, prefix: true, allow_nil: true

  scope :public_access, -> { joins(:questioning => :question).
    where("questions.access_level = 'inherit'") }
  scope :created_after, ->(date) { includes(:response).where("responses.created_at >= ?", date) }
  scope :created_before, ->(date) { includes(:response).where("responses.created_at <= ?", date) }
  scope :newest_first, -> { includes(:response).order("responses.created_at DESC") }

  # gets all location answers for the given mission
  # returns only the response ID and the answer value
  def self.location_answers_for_mission(mission, user = nil, options = {})
    response_conditions = { :mission_id => mission.try(:id) }

    # if the user is not a staffer or higher privilege, only show their own responses
    if user.present? && !user.role?(:staffer, mission)
      response_conditions[:user_id] = user.id
    end

    # return an AR relation
    joins(:response)
      .joins(%{LEFT JOIN `choices` ON `choices`.`answer_id` = `answers`.`id`})
      .where(:responses => response_conditions)
      .where(%{
        (`answers`.`latitude` IS NOT NULL AND `answers`.`longitude` IS NOT NULL)
        OR (`choices`.`latitude` IS NOT NULL AND `choices`.`longitude` IS NOT NULL)
      })
      .select(:response_id,
        %{COALESCE(`answers`.`latitude`, `choices`.`latitude`) AS `latitude`,
          COALESCE(`answers`.`longitude`, `choices`.`longitude`) AS `longitude`})
      .order('`answers`.`response_id` DESC')
      .paginate(:page => 1, :per_page => 1000)
  end

  # Tests if there exists at least one answer referencing the option and questionings with the given IDs.
  def self.any_for_option_and_questionings?(option_id, questioning_ids)
    find_by_sql(["SELECT COUNT(*) AS count FROM answers a LEFT OUTER JOIN choices c ON c.answer_id = a.id
      WHERE (a.option_id = ? OR c.option_id = ?) AND a.questioning_id IN (?)", option_id, option_id, questioning_ids]).first.count > 0
  end

  # Populates answer from odk-like string value.
  def populate_from_string(str)
    return if str.nil?

    if qtype.name == "select_one"
      # 'none' will be returned for a blank choice for a multilevel set.
      self.option_id = option_id_for_submission(str) unless str == 'none'

    elsif qtype.name == "select_multiple"
      str.split(' ').each{ |oid| choices.build(option_id: option_id_for_submission(oid)) }

    elsif qtype.temporal?
      # Strip timezone info for datetime and time.
      str.gsub!(/(Z|[+\-]\d+(:\d+)?)$/, '') unless qtype.name == 'date'

      val = Time.zone.parse(str)

      # Not sure why this is here. Investigate later.
      val = val.to_s(:"db_#{qtype.name}") unless qtype.has_timezone?

      self.send("#{qtype.name}_value=", val)

    else
      self.value = str
    end
  end

  # If this is an answer to a multilevel select_one question, returns the OptionLevel, else returns nil.
  def level
    option_set.try(:multi_level?) ? option_set.levels[(rank || 1) - 1] : nil
  end

  def choices_by_option
    @choice_hash ||= choices.select(&:checked?).index_by(&:option)
  end

  def all_choices
    # for each option, if we have a matching choice, just return it (checked? defaults to true)
    # otherwise create one and set checked? to false
    options.map{ |o| choices_by_option[o] || choices.new(option: o, checked: false) }
  end

  # if this answer is for a location question and the value is not blank, returns a two element array representing the
  # lat long. else returns nil
  def location
    if simple_location_answer?
      value.split(' ')
    else
      nil
    end
  end

  # returns the value for this answer casted to the appropriate data type
  def casted_value
    case qtype.name
    when 'date' then date_value
    when 'time' then time_value
    when 'datetime' then datetime_value
    when 'integer' then value.try(:to_i)
    when 'decimal' then value.try(:to_f)
    when 'select_one' then option_name
    when 'select_multiple' then choices.empty? ? nil : choices.map(&:option_name).join(';')
    else value.blank? ? nil : value
    end
  end

  # Returns a formatted string based on casted_value, or nil if casted_value is nil.
  def formatted_value
    cv = casted_value
    return nil if cv.nil?
    case qtype.name
    when 'datetime', 'date', 'time'
      cv.to_s(:"std_#{qtype.name}")
    else
      casted_value
    end
  end

  # relevant defaults to true until set otherwise
  def relevant?
    @relevant.nil? ? true : @relevant
  end
  alias_method :relevant, :relevant?

  # A flag indicating whether the answer is relevant and should thus be validated.
  # convert string 'true'/'false' to boolean
  def relevant=(r)
    @relevant = r.is_a?(String) ? r == "true" : r
  end

  # Checks if answer must be non-empty to be valid.
  # Non-first-rank answers are currently not required even if their questioning is required (i.e. partial answers allowed).
  def required_and_relevant?
    required? && !hidden? && relevant? && first_rank? && qtype.name != "select_multiple"
  end

  # Whether this Answer is the first in its set (i.e. rank is nil or 1)
  def first_rank?
    rank.nil? || rank == 1
  end

  # check various fields for blankness
  def empty?
    value.blank? && time_value.blank? && date_value.blank? && datetime_value.blank? && option_id.nil?
  end
  alias_method :blank?, :empty?

  # checks if answer is required and relevant but also empty
  def required_but_empty?
    required_and_relevant? && empty?
  end

  def should_validate?(field)
    # don't validate if response says no
    return false if response && !response.validate_answers?

    case field
    when :numericality
      qtype.numeric? && value.present?
    when :required
      # don't validate requiredness if response says no
      !(response && response.incomplete?)
    when :min_max
      value.present?
    else
      true
    end
  end

  def simple_location_answer?
    qtype.name == 'location' && value.present?
  end

  # check whether this answer has coordinates
  def has_coordinates?
    return false unless qtype.has_options?

    if option.present?
      # select_one
      option.has_coordinates?
    else
      # select_multiple
      choices.any?(&:has_coordinates?)
    end
  end

  def from_group?
    questioning && questioning.parent && questioning.parent.type == 'QingGroup'
  end

  def option_name
    option.canonical_name if option
  end

  def option_names
    choices.map(&:option).map(&:canonical_name).join(', ') if choices
  end

  def lat_lng
    latitude.present? && longitude.present? ? [latitude, longitude] : nil
  end

  private

    def required
      errors.add(:value, :required) if required_but_empty?
    end

    def round_ints
      self.value = value.to_i if qtype.name == "integer" && !value.blank?
      return true
    end

    def blanks_to_nulls
      self.value = nil if value.blank?
      return true
    end

    def min_max
      val_f = value.to_f
      if question.maximum && (val_f > question.maximum || question.maxstrictly && val_f == question.maximum) ||
         question.minimum && (val_f < question.minimum || question.minstrictly && val_f == question.minimum)
        errors.add(:value, question.min_max_error_msg)
      end
    end

    def clean_locations
      if simple_location_answer?
        if value.match(configatron.lat_lng_regexp)
          lat = number_with_precision($1.to_f, :precision => 6)
          lng = number_with_precision($3.to_f, :precision => 6)
          self.value = "#{lat} #{lng}"
        else
          self.value = ""
        end
      end
    end

    def replicate_location_values
      if simple_location_answer?
        lat, long = self.value.split(' ')
        self.latitude = BigDecimal.new(lat)
        self.longitude = BigDecimal.new(long)
      elsif option.present? && option.has_coordinates?
        self.latitude = option.latitude
        self.longitude = option.longitude
      end
    end

    # finds the appropriate Option instance for an ODK submission
    def option_id_for_submission(id_or_str)
      if id_or_str =~ /\Aon(\d+)\z/
        # look up inputs of the form "on####" as option node ids
        OptionNode.id_to_option_id($1)
      else
        # look up other inputs as option ids
        Option.where(id: id_or_str).pluck(:id).first
      end
    end
end
