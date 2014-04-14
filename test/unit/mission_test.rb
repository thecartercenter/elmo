require 'test_helper'

class MissionTest < ActiveSupport::TestCase

  test "all items related to that mission are removed when a mission is deleted" do
    mission = FactoryGirl.create(:mission_with_full_heirarchy)

    assert_difference('Mission.count', -1) do
      assert_difference('Broadcast.count', -1) do
        assert_difference('Form.count', -1) do
          assert_difference('Question.count', -3) do
            assert_difference('Subquestion.count', -2) do
              assert_difference('Option.count', -6) do
                assert_difference('OptionLevel.count', -2) do
                  assert_difference('OptionSet.count', -1) do
                    assert_difference('Report::Report.count', -1) do
                      mission.terminate_mission
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

end
