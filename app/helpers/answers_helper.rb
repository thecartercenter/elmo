module AnswersHelper
  def format_answer(answer, context)
    return '' if answer.nil?

    case answer.qtype.name
    when "select_one"
      answer.option.try(:name)
    when "select_multiple"
      answer.choices && answer.choices.map{|c| c.option.name}.join(', ')
    when "datetime", "date"
      answer.casted_value.present? ? I18n.l(answer.casted_value) : ''
    when "time"
      answer.time_value.present? ? I18n.l(answer.time_value, :format => :time_only) : ''
    when "decimal"
      answer.value.present? ? "%.2f" % answer.value.to_f : ''
    when "long_text"
      answer.value.present? ? (context == :table_cell ? truncate(answer.value, :length => 32) : answer.value) : ''
    else
      answer.value
    end
  end

  # generates an excerpt given a string and an excerpter
  # if excerpter or string is nil, just returns the string
  def safe_excerpt(str, excerpter)
    return str if excerpter.nil? || str.nil?
    excerpt_to_html(excerpter.excerpt!(str))
  end

  # assuming excerpts are enclosed with {{{ ... }}}, safely converts to <em> tags and returns html_safe string
  def excerpt_to_html(str)
    h(str).gsub('{{{', '<em class="match">').gsub('}}}', '</em>').html_safe
  end

  # checks for an excerpt for the given answer in the given response object and shows it if found
  # applies simple formatting
  def excerpt_if_exists(response, answer)
    html = if excerpt = response.excerpts_by_questioning_id[answer.questioning_id]
      excerpt_to_html(excerpt[:text])
    else
      answer.value
    end

    simple_format(html, {}, :sanitize => false)
  end
end
