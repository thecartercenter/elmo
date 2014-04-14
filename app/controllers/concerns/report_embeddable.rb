# methods required to embed a report display in a page
module ReportEmbeddable
  # sets up the @report_data structure which will be converted to json
  def build_report_data(options = {})
    @report_data = {:report => @report.as_json(:methods => :errors)}

    # merge in options from method call
    @report_data.merge!(options)

    # add stuff for report editing, if appropriate
    unless options[:read_only]
      @report_data[:options] = {
        :attribs => Report::AttribField.all,
        :forms => Form.for_mission(current_mission).by_name.as_json(:only => [:id, :name]),
        :calculation_types => Report::Calculation::TYPES,
        :questions => Question.for_mission(current_mission).includes(:forms, :option_set).by_code.as_json(
          :only => [:id, :code, :qtype_name],
          :methods => [:form_ids, :geographic?]
        ),
        :option_sets => OptionSet.for_mission(current_mission).by_name.as_json(:only => [:id, :name]),
        :percent_types => Report::Report::PERCENT_TYPES,

        # the names of qtypes that can be used in headers
        :headerable_qtype_names => QuestionType.all.select(&:headerable?).map(&:name)
      }
    end

    @report_data[:report][:generated_at] = I18n.l(Time.zone.now)
  end

  # runs the report and handles any errors, adding them to the flash
  # returns true if no errors, false otherwise
  def run_and_handle_errors
    begin
      @report.run(current_ability)
      return true
    rescue Report::ReportError, Search::ParseError
      flash.now[:error] = $!.to_s
      return false
    end
  end
end
