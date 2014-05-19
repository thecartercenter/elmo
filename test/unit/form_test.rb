require 'test_helper'

class FormTest < ActiveSupport::TestCase

  setup do
  end

  test "update ranks" do
    f = FactoryGirl.create(:form, :question_types => %w(integer integer))

    # reload form to ensure questions are sorted by rank
    f.reload

    # save ID of first questioning
    first_qing_id = f.questionings[0].id

    # swap ranks and save
    f.update_ranks(f.questionings[0].id.to_s => '2', f.questionings[1].id.to_s => '1')
    f.save!

    # now reload and make sure they're switched
    f.reload
    assert_equal(first_qing_id, f.questionings.last.id)
  end

  test "destroy questionings" do
    f = FactoryGirl.create(:form, :question_types => %w(integer decimal decimal integer))

    # remove the decimal questions
    f.destroy_questionings(f.questionings[1..2])
    f.reload

    # make sure they're gone and ranks are ok
    assert_equal(2, f.questionings.count)
    assert_equal([1,2], f.questionings.map(&:rank))
  end

  test "questionings count should work" do
    f = FactoryGirl.create(:form, :question_types => %w(integer integer))
    f.reload
    assert_equal(2, f.questionings_count)
  end

  test "all required" do
    f = FactoryGirl.create(:form, :question_types => %w(integer integer))
    assert_equal(false, f.all_required?)
    f.questionings.each{|q| q.required = true; q.save}
    assert_equal(true, f.all_required?)
  end

  test "form should create new version for itself when published" do
    f = FactoryGirl.create(:form)
    assert_nil(f.current_version)

    # publish and check again
    f.publish!
    f.reload
    assert_equal(1, f.current_version.sequence)

    # ensure form_id is set properly on version object
    assert_equal(f.id, f.current_version.form_id)

    # unpublish (shouldn't change)
    old = f.current_version.code
    f.unpublish!
    f.reload
    assert_equal(old, f.current_version.code)

    # publish again (shouldn't change)
    old = f.current_version.code
    f.publish!
    f.reload
    assert_equal(old, f.current_version.code)

    # unpublish, set upgrade flag, and publish (should change)
    old = f.current_version.code
    f.unpublish!
    f.flag_for_upgrade!
    f.publish!
    f.reload
    assert_not_equal(old, f.current_version.code)

    # unpublish and publish (shouldn't change)
    old = f.current_version.code
    f.unpublish!
    f.publish!
    f.reload
    assert_equal(old, f.current_version.code)
  end

  test "ranks should be fixed after deleting a question" do
    f = FactoryGirl.create(:form, :question_types => %w(integer integer integer))
    f.questions[1].destroy
    assert_equal(2, f.reload.questions.size)
    assert_equal(2, f.questionings.last.rank)
  end

  test "updating ranks improperly should trigger condition ordering error" do
    f = FactoryGirl.create(:form, :question_types => %w(integer integer integer))
    f.questionings[2].condition = FactoryGirl.build(:condition, :ref_qing => f.questionings[0], :op => 'lt', :value => 10)
    f.save!

    # we are specifically testing the update_ranks method here
    q1, q2, q3 = f.questionings

    # this one shouldn't raise since q with condition stays last
    f.update_ranks({q1.id.to_s => '2', q2.id.to_s => '1', q3.id.to_s => '3'})

    assert_raise(ConditionOrderingError) do
      f.update_ranks({q1.id.to_s => '3', q2.id.to_s => '2', q3.id.to_s => '1'})
    end
  end

  test "replicating and promoting a form should do a deep copy" do
    f = FactoryGirl.create(:form, :question_types => %w(select_one integer), :is_standard => false)
    f2 = f.replicate(:mode => :promote)

    # mission should now be nil and should be standard
    assert(f2.is_standard, "Newly promoted form should be a standard type.")
    assert_equal(nil, f2.mission)

    # all objects should be distinct
    assert_not_equal(f, f2)
    assert_not_equal(f.questionings[0], f2.questionings[0])
    assert_not_equal(f.questionings[0].question, f2.questionings[0].question)
    assert_not_equal(f.questionings[0].question.option_set, f2.questionings[0].question.option_set)
    assert_not_equal(f.questionings[0].question.option_set.optionings[0], f2.questionings[0].question.option_set.optionings[0])
    assert_not_equal(f.questionings[0].question.option_set.optionings[0].option, f2.questionings[0].question.option_set.optionings[0].option)

    # but properties should be same
    assert_equal(f.questionings[0].rank, f2.questionings[0].rank)
    assert_equal(f.questionings[0].question.code, f2.questionings[0].question.code)
    assert_equal(f.questionings[0].question.option_set.optionings[0].option.name, f2.questionings[0].question.option_set.optionings[0].option.name)

    # all f2 objects should be standard
    assert_equal(true, f2.questionings[0].is_standard?)
    assert_equal(true, f2.questionings[0].question.is_standard?)
    assert_equal(true, f2.questionings[0].question.option_set.is_standard?)
    assert_equal(true, f2.questionings[0].question.option_set.optionings[0].is_standard?)
    assert_equal(true, f2.questionings[0].question.option_set.optionings[0].option.is_standard?)
  end
end
