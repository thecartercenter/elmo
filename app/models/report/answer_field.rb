class Report::AnswerField < Report::Field

  attr_reader :question

  @@expression_params = [
    # name expressions for select questions
    {:sql_tplt => "__TBL_PFX__ao.name_translations", :name => "select_one_name", :clause => :select, :join => :options},
    {:sql_tplt => "__TBL_PFX__co.name_translations", :name => "select_multiple_name", :clause => :select, :join => :choices},

    # for select questions, we use the option rank as its value
    {:sql_tplt => "__TBL_PFX__ans_opt_stgs.rank", :name => "select_one_value", :clause => :select, :join => :options},
    {:sql_tplt => "__TBL_PFX__ch_opt_stgs.rank", :name => "select_multiple_value", :clause => :select, :join => :choices},

    # these question types have their own value columns
    {:sql_tplt => "CONVERT(__TBL_PFX__answers.value, SIGNED INTEGER)", :name => "integer_value", :clause => :select, :join => :answers},
    {:sql_tplt => "CONVERT(__TBL_PFX__answers.value, DECIMAL)", :name => "decimal_value", :clause => :select, :join => :answers},
    {:sql_tplt => "__TBL_PFX__answers.datetime_value", :name => "datetime_value", :clause => :select, :join => :answers},
    {:sql_tplt => "__TBL_PFX__answers.date_value", :name => "date_value", :clause => :select, :join => :answers},
    {:sql_tplt => "__TBL_PFX__answers.time_value", :name => "time_value", :clause => :select, :join => :answers},
    {:sql_tplt => "__TBL_PFX__answers.value", :name => "value", :clause => :select, :join => :answers},

    # sort expressions for select questions (using the rank value)
    {:sql_tplt => "__TBL_PFX__ans_opt_stgs.rank", :name => "select_one_sort", :clause => :select, :join => :options},
    {:sql_tplt => "__TBL_PFX__ch_opt_stgs.rank", :name => "select_multiple_sort", :clause => :select, :join => :choices},

    # this template uses the 'questions' table because the join class creates a table alias
    # the actual STI table name is 'questionables'
    {:sql_tplt => "__TBL_PFX__questions.id = __QUESTION_ID__", :name => "where_expr", :clause => :where, :join => :questions}
  ]

  def self.expression(options)
    Report::Expression.new(expression_params_by_name[options[:name]].merge(:chunks => options[:chunks]))
  end

  def self.expression_params_by_name
    @@expression_params_by_name ||= @@expression_params.index_by{|ep| ep[:name]}
  end

  def self.expression_params_by_clause
    @@expression_params_by_clause ||= @@expression_params.group_by{|ep| ep[:clause]}
  end

  def self.expressions_for_clause(clause, joins, chunks = {})
    expression_params_by_clause[clause].collect{|ep| Report::Expression.new(ep.merge(:chunks => chunks)) if joins.include?(ep[:join])}.compact
  end

  def initialize(question)
    @question = question
  end

  def name_expr(chunks)
    @name_expr ||= case data_type
    when "select_one", "select_multiple"
      self.class.expression(:name => "#{data_type}_name", :chunks => chunks)
    else
      value_expr(chunks)
    end
  end

  def value_expr(chunks)
    @value_expr ||= case data_type
    # for these types, there is a special value expression
    when "select_one", "select_multiple", "integer", "decimal", "datetime", "date", "time"
      self.class.expression(:name => "#{data_type}_value", :chunks => chunks)
    # else it's just the straight up value column
    else
      self.class.expression(:name => "value", :chunks => chunks)
    end
  end

  def where_expr(chunks)
    @where_expr ||= self.class.expression(:name => "where_expr", :chunks => chunks.merge(:question_id => @question.id))
    @where_expr
  end

  def sort_expr(chunks)
    case data_type
    when "select_one", "select_multiple"
      self.class.expression(:name => "#{data_type}_sort", :chunks => chunks)
    else
      value_expr(chunks)
    end
  end

  def data_type
    question.qtype.name
  end

  def joins
    case question.qtype.name
    when "select_multiple"
      [:choices]
    when "select_one"
      [:options]
    else
      [:questions]
    end
  end
end