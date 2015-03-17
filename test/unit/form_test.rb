require 'test_helper'

class FormTest < ActiveSupport::TestCase

  setup do
  end

  test "update ranks" do
    f = FactoryGirl.create(:form, :question_types => %w(integer integer))

    # reload form to ensure questions are sorted by rank
    f.root_questionings(reload = true)

    # save ID of first questioning
    first_qing_id = f.root_questionings[0].id

    # swap ranks and save
    f.update_ranks(f.root_questionings[0].id => 2, f.root_questionings[1].id => 1)
    f.save!

    # now reload and make sure they're switched
    assert_equal(first_qing_id, f.root_questionings(reload = true).last.id)
  end

  test "destroy questionings" do
    f = FactoryGirl.create(:form, :question_types => %w(integer decimal decimal integer))

    # remove the decimal questions
    f.destroy_questionings(f.root_questionings[1..2])
    f.reload

    # make sure they're gone and ranks are ok
    assert_equal(2, f.root_questionings.count)

    assert_equal([1,2], f.root_questionings.map(&:rank))
  end

  test "questionings count should work" do
    f = FactoryGirl.create(:form, :question_types => %w(integer integer))
    f.reload
    assert_equal(2, f.root_questionings.count)
  end

  test "all required" do
    f = FactoryGirl.create(:form, :question_types => %w(integer integer))
    assert_equal(false, f.all_required?)
    f.root_questionings.each{|q| q.required = true; q.save}
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
    assert_equal(2, f.root_questionings.last.rank)
  end

  test "updating ranks improperly should trigger condition ordering error" do
    f = FactoryGirl.create(:form, :question_types => %w(integer integer integer))
    f.root_questionings[2].condition = FactoryGirl.build(:condition, :ref_qing => f.root_questionings[0], :op => 'lt', :value => 10)
    f.save!

    # we are specifically testing the update_ranks method here
    q1, q2, q3 = f.root_questionings

    # this one shouldn't raise since q with condition stays last
    f.update_ranks({q1.id => 2, q2.id => 1, q3.id => 3})

    assert_raise(ConditionOrderingError) do
      f.update_ranks({q1.id => 3, q2.id => 2, q3.id => 1})
    end
  end
end
