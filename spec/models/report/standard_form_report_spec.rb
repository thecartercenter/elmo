# There are more report tests in test/unit/report.
require 'spec_helper'

describe Report::StandardFormReport do
  context "basic" do
    before do
      @new_report = Report::StandardFormReport.new
    end

    it "form_id should default to nil" do
      assert_nil(@new_report.form_id)
    end

    it "question_order should default to number" do
      assert_equal('number', @new_report.question_order)
    end

    it "text_responses should default to all" do
      assert_equal('all', @new_report.text_responses)
    end

    it "form foreign key should work" do
      @new_report.form = create(:form)
      expect(@new_report.form).not_to be_nil
    end

    it "should return correct response count" do
      build_form_and_responses
      Rails.logger.debug('----------------------------------------------------------------------------------------------')
      build_and_run_report
      assert_equal(5, @report.response_count)
    end

    it "should return correct response count for a coordinator" do
      coordinator = get_user
      ability = Ability.new(:user => coordinator, :mission => get_mission)

      build_form_and_responses

      @report = create(:standard_form_report, :form => @form)
      @report.run(ability)

      assert_equal(5, @report.response_count)
    end

    it "should return correct response count for an observer" do
      observer = create(:user, :role_name => :observer)
      ability = Ability.new(:user => observer, :mission => get_mission)

      build_form_and_responses

      @report = create(:standard_form_report, :form => @form)
      @report.run(ability)

      assert_equal(0, @report.response_count)
    end

    it "should not contain invisible questionings" do
      build_form_and_responses

      # make one question invisible
      @form.questionings[1].update_attributes!(hidden: true)

      build_and_run_report

      assert(!@report.subsets[0].summaries.map(&:questioning).include?(@form.questionings[1]), "summaries should not contain hidden question")
    end

    it "should return summaries matching questions" do
      build_form_and_responses
      build_and_run_report
      assert_equal('decimal', @report.subsets[0].summaries[2].qtype.name)

      # We leave out the last questioning on the form since location questions should not be included.
      assert_equal(@form.questionings[0..3], @report.subsets[0].summaries.map(&:questioning))
    end

    it "should return non-submitting observers" do
      # make observers
      observers = %w(bob jojo cass sal).map{|n| create(:user, :login => n, :role_name => :observer)}

      # make decoy coord and admin users
      coord = create(:user, :role_name => :coordinator)
      admin = create(:user, :role_name => :observer, :admin => true)

      # make simple form and add responses from first two users
      @form = create(:form)
      observers[0...2].each{|o| create(:response, :form => @form, :user => o)}

      # run report and check missing observers
      build_and_run_report
      assert_equal(%w(cass sal), @report.users_without_responses(:role => :observer).map(&:login).sort)
    end

    it "empty? should be false if responses" do
      build_form_and_responses
      build_and_run_report
      assert(!@report.empty?, "report should not be empty")
    end

    it "empty? should be true if no responses" do
      build_form_and_responses(:response_count => 0)
      build_and_run_report
      assert(@report.empty?, "report should be empty")
    end

    it "empty? should be true if no questions" do
      @form = create(:form)
      build_and_run_report
      assert(@report.empty?, "report should be empty")
    end

    it "with numeric question order should have single summary group" do
      build_form_and_responses
      build_and_run_report # defaults to numeric order
      assert_equal(1, @report.subsets[0].tag_groups[0].type_groups.size)
      assert_equal('all', @report.subsets[0].tag_groups[0].type_groups[0].type_set)
    end

  end

  context "on destroy" do
    before do
      @form = create(:form, question_types: %w(select_one integer))
      @report = create(:standard_form_report, form: @form, disagg_qing: @form.questionings[1])
    end

    it 'should have disagg_qing nullified when questioning destroyed' do
      @form.questionings[1].destroy
      expect(@report.reload.disagg_qing).to be_nil
    end

    it 'should be destroyed when form destroyed' do
      @form.destroy
      expect(Report::Report.exists?(@report.id)).to be false
    end
  end

  def build_form_and_responses(options = {})
    @form = create(:form, :question_types => %w(integer integer decimal select_one location))
    (options[:response_count] || 5).times do
      create(:response, :form => @form, :answer_values => [1, 2, 1.5, nil, 'Cat'])
    end
  end

  def build_and_run_report
    # assume we are running as admin
    @user = create(:user, :admin => true)
    @report = create(:standard_form_report, :form => @form)
    @report.run(Ability.new(:user => @user, :mission => get_mission))
  end
end
