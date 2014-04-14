require 'xml'
class Response < ActiveRecord::Base
  include MissionBased
  include Cacheable

  belongs_to(:form, :inverse_of => :responses, :counter_cache => true)
  has_many(:answers, :include => :questioning, :order => "questionings.rank",
    :autosave => true, :dependent => :destroy, :inverse_of => :response)
  belongs_to(:user, :inverse_of => :responses)

  has_many(:location_answers, :include => {:questioning => :question}, :class_name => 'Answer',
    :conditions => "questionables.qtype_name = 'location'", :order => 'questionings.rank')

  attr_accessor(:modifier, :excerpts)

  # we turn off validate above and do it here so we can control the message and have only one message
  # regardless of how many answer errors there are
  validates(:user, :presence => true)
  validate(:no_missing_answers)

  default_scope(includes(:form, :user).order("responses.created_at DESC"))
  scope(:unreviewed, where(:reviewed => false))
  scope(:by, lambda{|user| where(:user_id => user.id)})

  # loads all the associations required for show, edit, etc.
  scope(:with_associations, includes(
    :form, {
      :answers => [
        {:choices => :option},
        :option,
        {:questioning => [:condition, {:question => {:option_set => :options}}]}
      ]
    }
  ))

  # loads basic belongs_to associations
  scope(:with_basic_assoc, includes(:form, :user))

  # loads only some answer info
  scope(:with_basic_answers, includes(:answers => {:questioning => :question}))

  # loads only answers with location info
  scope(:with_location_answers, includes(:location_answers))

  # takes a Relation, adds a bunch of selects and joins, and uses find_by_sql to do the actual finding
  # this technique is due to limitations (at the time of dev) in the Relation system
  def self.for_export(rel)
    find_by_sql(export_sql(rel))
  end

  # gets the list of fields to be searched for this class
  # includes whether they should be included in a default, unqualified search
  # and whether they are searchable by a regular expression
  def self.search_qualifiers(scope)
    [
      Search::Qualifier.new(:name => "form", :col => "forms.name", :assoc => :forms),
      Search::Qualifier.new(:name => "reviewed", :col => "responses.reviewed"),
      Search::Qualifier.new(:name => "submitter", :col => "users.name", :assoc => :users, :type => :text),
      Search::Qualifier.new(:name => "source", :col => "responses.source"),
      Search::Qualifier.new(:name => "submit_date", :col => "DATE(CONVERT_TZ(responses.created_at, 'UTC', '#{Time.zone.mysql_name}'))", :type => :scale),

      # this qualifier matches responses that have answers to questions with the given option set
      Search::Qualifier.new(:name => "option_set", :col => "option_sets.name", :assoc => :option_sets),

      # this qualifier matches responses that have answers to questions with the given type
      # this and other qualifiers use the 'questions' table because the join code below creates a table alias
      # the actual STI table name is 'questionables'
      Search::Qualifier.new(:name => "question_type", :col => "questions.qtype_name", :assoc => :questions),

      # this qualifier matches responses that have answers to the given question
      Search::Qualifier.new(:name => "question", :col => "questions.code", :assoc => :questions),

      # this qualifier inserts a placeholder that we replace later
      Search::Qualifier.new(:name => "text", :col => "responses.id", :type => :indexed, :default => true),

      # support {foobar}:stuff style searches, where foobar is a question code
      Search::Qualifier.new(:name => "text_by_code", :pattern => /^\{(#{Question::CODE_FORMAT})\}$/, :col => "responses.id",
        :type => :indexed, :validator => ->(md){ Question.exists?(:mission_id => scope[:mission].id, :code => md[1]) })
    ]
  end

  # searches for responses
  # relation - a Response relation upon which to build the search query
  # query - the search query string (e.g. form:polling text:interference, tomfoolery)
  # scope - the scope to pass to the search qualifiers generator
  # options[:include_excerpts] - if true, execute the query and return the results with answer excerpts (if applicable) included;
  #   if false, doesn't execute the query and just returns the relation
  # options[:dont_truncate_excerpts] - if true, excerpt length limit is very high, so full answer is returned with matches highlighted
  def self.do_search(relation, query, scope, options = {})
    options[:include_excerpts] ||= false

    # create a search object and generate qualifiers
    search = Search::Search.new(:str => query, :qualifiers => search_qualifiers(scope))

    # apply the needed associations
    relation = relation.joins(Report::Join.list_to_sql(search.associations))

    # get the sql
    sql = search.sql

    sphinx_param_sets = []

    # replace any fulltext search placeholders
    sql = sql.gsub(/###(\d+)###/) do
      # the matched number is the index of the expression in the search's expression list
      expression = search.expressions[$1.to_i]

      # search all answers in this mission for a match
      # not escaping the query value because double quotes were getting escaped which makes exact phrase not work
      attribs = {:mission_id => scope[:mission].id}

      if expression.qualifier.name == "text_by_code"
        # get qualifier text (e.g. {form}) and strip outer braces
        question_code = expression.qualifier_text[1..-2]

        # get the question with the given code
        question = Question.where(:mission_id => scope[:mission].id).where(:code => question_code).first

        # raising here since this shouldn't happen due to validator
        raise "question with code '#{question_code}' not found" if question.nil?

        # add an attrib to this sphinx search
        attribs[:question_id] = question.id
      end

      # save the search params as we'll need them again
      sphinx_params = [expression.values, {:with => attribs, :max_matches => 1000000, :per_page => 1000000}]
      sphinx_param_sets << sphinx_params

      # run the sphinx search
      answer_ids = Answer.search_for_ids(*sphinx_params)

      # turn into an sql fragment
      if answer_ids.empty?
        "0"
      else
        # get all response IDs and join into string
        Answer.connection.execute("SELECT DISTINCT response_id FROM answers WHERE answers.id IN (#{answer_ids.join(',')})").to_a.flatten.join(',')
      end
    end

    # apply the conditions
    relation = relation.where(sql)

    # do excerpts
    if !sphinx_param_sets.empty? && options[:include_excerpts]

      # get matches
      responses = relation.all

      unless responses.empty?
        responses_by_id = responses.index_by(&:id)

        # run answer searches again, but this time restricting response_ids to the matches responses
        sphinx_param_sets.each do |sphinx_params|

          # run search again
          sphinx_params[1][:with][:response_id] = responses_by_id.keys
          sphinx_params[1][:sql] = {:include => {:questioning => :question}}
          answers = Answer.search(*sphinx_params)

          excerpter_options = {:before_match => '{{{', :after_match => '}}}', :chunk_separator => ' ... ', :query_mode => true}
          excerpter_options[:limit] = 1000000 if options[:dont_truncate_excerpts]

          # create excerpter
          excerpter = ThinkingSphinx::Excerpter.new('answer_core', sphinx_params[0], excerpter_options)

          # for each matching answer, add to excerpt to appropriate response
          answers.each do |a|
            r = responses_by_id[a.response_id]
            r.excerpts ||= []
            r.excerpts << {:questioning_id => a.questioning_id, :code => a.questioning.code, :text => excerpter.excerpt!(a.value)}
          end
        end
      end

      # return responses
      responses
    else
      # no excerpts, just return the relation
      relation
    end
  end

  # returns a count how many responses have arrived recently
  # format e.g. [5, "week"] (5 in the last week)
  # nil means no recent responses
  def self.recent_count(rel)
    %w(hour day week month year).each do |p|
      if (count = rel.where("created_at > ?", 1.send(p).ago).count) > 0
        return [count, p]
      end
    end
    nil
  end

  # returns an array of N response counts grouped by form
  # uses the WHERE clause from the given relation
  def self.per_form(rel, n)
    where_clause = rel.arel.send(:where_clauses).join(' AND ')
    where_clause = '1=1' if where_clause.empty?

    find_by_sql("
      SELECT forms.name AS form_name, COUNT(responses.id) AS count
      FROM responses INNER JOIN forms ON responses.form_id = forms.id
      WHERE #{where_clause}
      GROUP BY forms.id, forms.name
      ORDER BY count DESC
      LIMIT #{n}")
  end

  # generates a cache key for the set of all responses for the given mission.
  # the key will change if the number of responses changes, or if a response is updated.
  def self.per_mission_cache_key(mission)
    count_and_date_cache_key(:rel => unscoped.for_mission(mission), :prefix => "mission-#{mission.id}")
  end

  # whether the answers should validate themselves
  def validate_answers?
    # dont validate if this is an ODK submission as we don't want to lose data
    modifier != 'odk'
  end

  def populate_from_xml(xml)
    # response mission should already be set
    raise "xml submissions must have a mission" if mission.nil?

    # parse xml
    doc = XML::Parser.string(xml).parse

    # set the source/modifier values to odk
    self.source = self.modifier = "odk"

    # if no root ID, error
    raise ArgumentError.new("no form id was given") if doc.root['id'].nil?

    # get form ID and version sequence number and attempt to convert to int
    form_id = doc.root['id'].try(:to_i)
    form_ver = doc.root['version'].try(:to_i)

    # if either of these is nil or not an integer, error
    raise ArgumentError.new("no form id was given") if form_id.nil?
    raise FormVersionError.new("form version must be specified") if form_ver.nil?

    # try to load form (will raise activerecord error if not found)
    self.form = Form.find(form_id)

    # if form has no version, error
    raise "xml submissions must be to versioned forms" if form.current_version.nil?

    # if form version is outdated, error
    raise FormVersionError.new("form version is outdated") if form.current_version.sequence > form_ver

    # get the visible questionings
    qings = form.visible_questionings

    # loop over each child tag and create hash of question_code => value
    values = {}; doc.root.children.each{|c| values[c.name] = c.first? ? c.first.content : nil}

    # loop over all the questions in the form and create answers
    qings.each do |qing|
      # get value from hash
      str = values[qing.question.odk_code]

      # add answer
      answer = Answer.new_from_str(:str => str, :questioning => qing)
      self.answers << answer

      # set incomplete flag if required but empty
      self.incomplete = true if answer.required_but_empty?
    end
  end

  def visible_questionings
    # get visible questionings from form
    form.visible_questionings
  end

  def all_answers
    # make sure there is an associated answer object for each questioning in the form
    visible_questionings.collect{|qing| answer_for(qing) || answers.build(:questioning => qing)}
  end

  def all_answers=(params)
    # do a match on current and newer ids with the ID as the comparator
    answers.compare_by_element(params.values, Proc.new{|a| a[:questioning_id].to_i}) do |orig, subd|
      # if both exist, update the original
      if orig && subd
        orig.attributes = subd
      # if submitted is nil, destroy the original
      elsif subd.nil?
        answers.delete(orig)
      # if original is nil, add the new one to this response's array
      elsif orig.nil?
        answers.build(subd)
      end
    end
  end

  def answer_for(questioning)
    # get the matching answer(s)
    answer_for_qing[questioning]
  end

  def answer_for_qing(options = {})
    @answer_for_qing = nil if options[:rebuild]
    @answer_for_qing ||= answers.index_by(&:questioning)
  end

  def answer_for_question(question)
    (@answers_by_question ||= answers.index_by(&:question))[question]
  end

  # returns an array of required questionings for which answers are missing
  def missing_answers
    return @missing_answers if @missing_answers
    answer_for_qing(:rebuild => true)
    @missing_answers = visible_questionings.collect do |qing|
      (answer_for(qing).nil? && qing.required?) ? qing : nil
    end.compact
  end

  # if this response contains location questions, returns the gps location (as a 2 element array)
  # of the first such question on the form, else returns nil
  def location
    ans = location_answers.first
    ans ? ans.location : nil
  end

  # indexes excerpts by questioning_id
  def excerpts_by_questioning_id
    @excerpts_by_questioning_id ||= (excerpts || []).index_by{|e| e[:questioning_id]}
  end

  private
    def no_missing_answers
      errors.add(:base, :missing_answers) unless missing_answers.empty? || incomplete?
    end

    def self.export_sql(rel)
      # add all the selects
      # assumes the language desired is English. currently does not respect the locale
      rel = rel.select("responses.id AS response_id")
      rel = rel.select("responses.created_at AS submission_time")
      rel = rel.select("responses.reviewed AS is_reviewed")
      rel = rel.select("forms.name AS form_name")

      # these expressions use 'questions' because the join code below creates a table alias
      # the actual STI table name is 'questionables'
      rel = rel.select("questions.code AS question_code")
      rel = rel.select("questions._name AS question_name")
      rel = rel.select("questions.qtype_name AS question_type")

      rel = rel.select("users.name AS submitter_name")
      rel = rel.select("answers.id AS answer_id")
      rel = rel.select("answers.value AS answer_value")
      rel = rel.select("answers.datetime_value AS answer_datetime_value")
      rel = rel.select("answers.date_value AS answer_date_value")
      rel = rel.select("answers.time_value AS answer_time_value")
      rel = rel.select("IFNULL(ao._name, co._name) AS choice_name")
      rel = rel.select("option_sets.name AS option_set")

      # add all the joins
      rel = rel.joins(Report::Join.list_to_sql([:users, :forms,
        :answers, :questionings, :questions, :option_sets, :options, :choices]))

      rel.to_sql
    end
end
