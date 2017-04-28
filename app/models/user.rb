class User < ApplicationRecord
  include Cacheable

  ROLES = %w[observer reviewer staffer coordinator]
  SESSION_TIMEOUT = (Rails.env.development? ? 2.weeks : 60.minutes)
  SITE = new name: configatron.site_shortname # Dummy user for use in SMS log
  GENDER_OPTIONS = %w[man woman no_answer specify]
  PASSWORD_FORMAT = /(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])/

  attr_writer(:reset_password_method)
  attr_accessor(:batch_creation)
  alias :batch_creation? :batch_creation

  has_many :responses, inverse_of: :user
  has_many :broadcast_addressings, inverse_of: :addressee, foreign_key: :addressee_id, dependent: :destroy
  has_many :form_forwardings, inverse_of: :recipient, foreign_key: :recipient_id, dependent: :destroy
  has_many :assignments, autosave: true, dependent: :destroy, validate: true, inverse_of: :user
  has_many :missions, -> { order "missions.created_at DESC" }, through: :assignments
  has_many :operations, inverse_of: :creator, foreign_key: :creator_id, dependent: :destroy
  has_many :reports, inverse_of: :creator, foreign_key: :creator_id, dependent: :nullify, class_name: 'Report::Report'
  has_many :user_group_assignments, dependent: :destroy
  has_many :user_groups, through: :user_group_assignments
  belongs_to :last_mission, class_name: 'Mission'

  accepts_nested_attributes_for(:assignments, allow_destroy: true)
  accepts_nested_attributes_for(:user_groups)

  acts_as_authentic do |c|
    c.transition_from_crypto_providers = [Authlogic::CryptoProviders::Sha512]
    c.crypto_provider = Authlogic::CryptoProviders::SCrypt

    c.disable_perishable_token_maintenance = true
    c.perishable_token_valid_for = 1.week
    c.logged_in_timeout(SESSION_TIMEOUT)

    c.validates_format_of_login_field_options = {with: /\A[a-zA-Z0-9\._]+\z/}
    c.merge_validates_uniqueness_of_login_field_options(unless: Proc.new{|u| u.batch_creation?})

    c.merge_validates_length_of_password_field_options(minimum: 8,
                                                       unless: Proc.new{|u| u.batch_creation?})

    # email is not mandatory, but must be valid if given
    c.merge_validates_format_of_email_field_options(allow_blank: true)
    c.merge_validates_uniqueness_of_email_field_options(unless: Proc.new{|u| u.batch_creation? ||
                                                                                u.email.blank?})
  end

  after_initialize(:set_default_pref_lang)
  before_validation(:normalize_fields)
  before_validation(:generate_password_if_none)
  after_create(:regenerate_api_key, unless: :batch_creation?)
  after_create(:regenerate_sms_auth_code)
  # call before_destroy before dependent: :destroy associations
  # cf. https://github.com/rails/rails/issues/3458
  before_destroy(:check_assoc)
  before_save(:clear_assignments_without_roles)

  normalize_attribute :login, with: [:strip, :downcase]

  validates(:name, presence: true)
  validates(:pref_lang, presence: true)
  validate(:phone_length_or_empty)
  validate(:must_have_password_reset_on_create)
  validate(:password_reset_cant_be_email_if_no_email)
  validate(:print_password_reset_only_for_observer)
  validate(:no_duplicate_assignments)
  # This validation causes issues when deleting missions,
  # orphaned users can no longer change their profile or password
  # which can be an issue if they will be being re-assigned
  # validate(:must_have_assignments_if_not_admin)
  validate(:phone_should_be_unique, unless: :batch_creation?)
  validates :password, format: { with: PASSWORD_FORMAT,
                                 if: :require_password?,
                                 unless: :batch_creation?,
                                 message: :invalid_password }

  scope(:by_name, -> { order("users.name") })
  scope(:assigned_to, ->(m) { where("users.id IN (SELECT user_id FROM assignments WHERE mission_id = ?)", m.try(:id)) })
  scope(:with_assoc, -> {
    includes(:missions, { assignments: :mission }, { user_group_assignments: :user_group } )
  })
  scope(:with_groups, -> { joins(:user_groups) })
  scope :name_matching, ->(q) { where("name LIKE ?", "%#{q}%") }
  scope :with_roles, -> (m, roles) { includes(:missions, { assignments: :mission }).where(assignments: { mission: m.try(:id), role: roles }) }

  # returns users who are assigned to the given mission OR who submitted the given response
  scope(:assigned_to_or_submitter, ->(m, r) { where("users.id IN (SELECT user_id FROM assignments WHERE mission_id = ?) OR users.id = ?", m.try(:id), r.try(:user_id)) })

  def self.random_password(size = 12)
    size = 12 if size < 12

    num_size = size.even? ? 2 : 3
    symbol_size = 2
    alpha_size = (size - num_size - symbol_size) / 2

    num = %w{2 3 4 6 7 9}
    alpha = %w{a c d e f g h j k m n p q r t v w x y z}
    symbol = %w{@ & # + %}

    alpha_component = alpha_size.times.map { alpha.sample }
    upper_component = alpha_size.times.map { alpha.sample.upcase }
    num_component = num_size.times.map { num.sample }
    symbol_component = symbol_size.times.map { symbol.sample }

    (alpha_component + upper_component + num_component + symbol_component).shuffle.join
  end

  def self.find_by_credentials(login, password)
    user = find_by_login(login)
    (user && user.valid_password?(password)) ? user : nil
  end

  def self.search_qualifiers
    [
      Search::Qualifier.new(name: "name", col: "users.name", type: :text, default: true),
      Search::Qualifier.new(name: "login", col: "users.login", type: :text, default: true),
      Search::Qualifier.new(name: "email", col: "users.email", type: :text, default: true),
      Search::Qualifier.new(name: "phone", col: "users.phone", type: :text),
      Search::Qualifier.new(name: "group", col: "user_groups.name", type: :text, assoc: :user_groups)
    ]
  end

  # searches for users
  # relation - a User relation upon which to build the search query
  # query - the search query string (e.g. name:foo)
  def self.do_search(relation, query)
    # create a search object and generate qualifiers
    search = Search::Search.new(str: query, qualifiers: search_qualifiers)

    # add associations
    relation = relation.joins(search.associations)

    # get the sql
    sql = search.sql

    # apply the conditions
    relation = relation.where(sql)
  end


  # Returns an array of hashes of format {name: "Some User", response_count: 2}
  # of observer response counts for the given mission
  def self.sorted_observer_response_counts(mission, limit)
    #First it tries to get user observers that don't have any response
    result = self.observers_without_responses(mission, limit)
    return result unless result.length < limit

    # If the first query didn't get the necessary users quantity,
    # we then get the ones with lowest activy
    find_by_sql(["SELECT users.name, rc.response_count FROM users
      JOIN (
        SELECT assignments.user_id, COUNT(DISTINCT responses.id) AS response_count
        FROM assignments
          LEFT JOIN responses ON responses.user_id = assignments.user_id AND responses.mission_id = ?
        WHERE assignments.role = 'observer' AND assignments.mission_id = ?
        GROUP BY assignments.user_id        ORDER BY response_count        LIMIT ?
      ) as rc ON users.id = rc.user_id", mission.id, mission.id, limit]).reverse
  end

  # Returns an array of hashes of format {name: "Some User", response_count: 0}
  # of observers that doesn't have responses on the mission
  def self.observers_without_responses(mission, limit)
    find_by_sql(["SELECT users.name, 0 as response_count FROM users
      JOIN (
        SELECT a.user_id FROM assignments a
        WHERE NOT EXISTS (
          SELECT 1 FROM responses r
          WHERE r.user_id = a.user_id AND r.mission_id = ?
        ) AND a.role='observer' AND a.mission_id = ? LIMIT ?
      ) as rc ON users.id = rc.user_id
      ORDER BY users.name", mission.id, mission.id, limit])
  end

  # Returns all non-admin users in the form's mission with the given role that have
  # not submitted any responses to the form
  #
  # options[:role] the role to check for
  # options[:limit] how many users we want to fetch from the db. This method returns at most
  #   one more than this number so you can report truncation to the user.
  def self.without_responses_for_form(form, options)
    find_by_sql(["SELECT * FROM users
      INNER JOIN assignments ON assignments.user_id = users.id WHERE
      assignments.mission_id = ? AND
      assignments.role = ? AND
      users.admin = FALSE AND
      NOT EXISTS (
        SELECT 1 FROM responses WHERE
        responses.user_id=users.id AND
        responses.form_id = ?
      )
      ORDER BY users.name
      LIMIT ?", form.mission.id, options[:role].to_s, form.id, options[:limit] + 1])
  end

  # generates a cache key for the set of all users for the given mission.
  # the key will change if the number of users changes, or if a user is updated.
  def self.per_mission_cache_key(mission)
    count_and_date_cache_key(rel: unscoped.assigned_to(mission), prefix: "mission-#{mission.id}")
  end

  def self.by_phone(phone)
    where("phone = ? OR phone2 = ?", phone, phone).first
  end

  def reset_password
    self.password = self.password_confirmation = self.class.random_password
  end

  def deliver_intro!
    reset_perishable_token!
    Notifier.intro(self).deliver_now
  end

  # sends password reset instructions to the user's email
  def deliver_password_reset_instructions!
    reset_perishable_token!
    Notifier.password_reset_instructions(self).deliver_now
  end

  def full_name
    name
  end

  def group_names
    user_groups.map(&:name).join(", ")
  end

  def active?
    self.active
  end

  def activate!(bool)
    update_attribute(:active, bool)
  end

  def reset_password_method
    @reset_password_method.nil? ? "dont" : @reset_password_method
  end

  def reset_password_if_requested
    if %w[email print].include?(reset_password_method)
      reset_password and save
    end
    if reset_password_method == "email"
      # only send intro if he/she has never logged in
      (login_count || 0) > 0 ? deliver_password_reset_instructions! : deliver_intro!
    end
  end

  def to_vcf
    "BEGIN:VCARD\nVERSION:3.0\nFN:#{name}\n" +
    (email ? "EMAIL:#{email}\n" : "") +
    (phone ? "TEL;TYPE=CELL:#{phone}\n" : "") +
    (phone2 ? "TEL;TYPE=CELL:#{phone2}\n" : "") +
    "END:VCARD"
  end

  def can_get_sms?
    !(phone.blank? && phone2.blank?)
  end

  def can_get_email?
    !email.blank?
  end

  def assignments_by_mission
    @assignments_by_mission ||= Hash[*assignments.collect{|a| [a.mission, a]}.flatten]
  end

  # returns the last mission with which this user is associated
  def latest_mission
    # the mission association is already sorted by date so we just take the last one
    missions[missions.size-1]
  end

  # gets the user's role for the given mission
  # returns nil if the user is not assigned to the mission
  def role(mission)
    nn(assignments_by_mission[mission]).role
  end

  # checks if the user can perform the given role for the given mission
  # mission defaults to user's current mission
  def role?(base_role, mission)
    # admins can do anything
    return true if admin?

    # if no mission then the answer is trivially false
    return false if mission.nil?

    # get the user's role for the specified mission
    mission_role = role(mission)

    # if the role is nil, we can return false
    if mission_role.nil?
      return false
    # otherwise we compare the role indices
    else
      ROLES.index(base_role.to_s) <= ROLES.index(mission_role)
    end
  end

  def observer_only?
    assignments.all?{ |a| a.role === "observer" }
  end

  def session_time_left
    SESSION_TIMEOUT - (Time.now - last_request_at)
  end

  def current_login_age
    Time.now - current_login_at if current_login_at.present?
  end

  def current_login_recent?(max_age=nil)
    max_age ||= configatron.recent_login_max_age

    current_login_age < max_age if current_login_at.present?
  end

  # returns hash of missions to roles
  def roles
    Hash[*assignments.map{|a| [a.mission, a.role]}.flatten]
  end

  def regenerate_api_key
    # loop if necessary till unique token generated
    begin
      self.api_key = SecureRandom.hex
    end while User.exists?(api_key: api_key)
    save(validate: false)
  end

  # regenerates sms auth code
  def regenerate_sms_auth_code
    begin
      self.sms_auth_code = Random.alphanum(4)
    end while User.exists?(sms_auth_code: sms_auth_code)
    save(validate: false)
  end

  # Returns the system's best guess as to which mission this user would like to see.
  def best_mission
    if last_mission && (admin? || assignments.map(&:mission).include?(last_mission))
      last_mission
    elsif assignments.any?
      assignments.sort_by(&:updated_at).last.mission
    else
      nil
    end
  end

  def remember_last_mission(mission)
    self.last_mission = mission
    save validate: false
  end

  # OVERRIDE AUTHLOGIC METHOD.
  # This is to avoid unnecessary queries to the database if we want to skip
  # certain validations.
  #
  # Resets the persistence_token field to a random hex value.
  def reset_persistence_token
    super unless batch_creation?
  end

  private
    def normalize_fields
      %w(phone phone2 name email).each{|f| self.send("#{f}").try(:strip!)}
      self.email = nil if email.blank?
      self.phone = PhoneNormalizer.normalize(phone)
      self.phone2 = PhoneNormalizer.normalize(phone2)
      return true
    end

    def phone_length_or_empty
      errors.add(:phone, :at_least_digits, num: 9) unless phone.blank? || phone.size >= 10
      errors.add(:phone2, :at_least_digits, num: 9) unless phone2.blank? || phone2.size >= 10
    end

    def check_assoc
      # can't delete users with related responses.
      raise DeletionError.new(:cant_delete_if_responses) unless responses.empty?

      # can't delete users with related sms messages.
      raise DeletionError.new(:cant_delete_if_sms_messages) unless Sms::Message.where(user_id: id).empty?
    end

    def must_have_password_reset_on_create
      if new_record? && reset_password_method == "dont"
        errors.add(:reset_password_method, :blank)
      end
    end

    def password_reset_cant_be_email_if_no_email
      if reset_password_method == "email" && email.blank?
        verb = new_record? ? "send" : "reset"
        errors.add(:reset_password_method, :cant_passwd_email, verb: verb)
      end
    end

    def print_password_reset_only_for_observer
      if reset_password_method == "print" && !observer_only?
        errors.add(:reset_password_method, :print_password_reset_only_for_observer)
      end
    end

    def no_duplicate_assignments
      errors.add(:assignments, :duplicate_assignments) if Assignment.duplicates?(assignments.reject{|a| a.marked_for_destruction?})
    end

    def must_have_assignments_if_not_admin
      if !admin? && assignments.reject{|a| a.marked_for_destruction?}.empty?
        errors.add(:assignments, :cant_be_empty_if_not_admin)
      end
    end

    def clear_assignments_without_roles
      assignments.delete(assignments.select(&:no_role?))
    end

    # ensures phone and phone2 are unique
    def phone_should_be_unique
      [:phone, :phone2].each do |field|
        val = send(field)
        # if phone/phone2 is not nil and we can find a user with a different ID from ours that has a matching phone OR phone2
        # then it's not unique
        # start building relation
        rel = User.where("phone = ? OR phone2 = ?", val, val)
        # add ID clause if this is not a new record
        rel = rel.where("id != ?", id) unless new_record?
        if !val.nil? && rel.count > 0
          errors.add(field, :phone_assigned_to_other)
        end
      end
    end

    # generates a random password before validation if this is a new record, unless one is already set
    def generate_password_if_none
      reset_password if new_record? && password.blank? && password_confirmation.blank?
    end

    # sets the user's preferred language to the mission default
    def set_default_pref_lang
      begin
        self.pref_lang ||= configatron.has_key?(:preferred_locales) ? configatron.preferred_locales.first.to_s : 'en'
      rescue ActiveModel::MissingAttributeError
        # we rescue this error in case find_by_sql is being used
      end
    end
end
