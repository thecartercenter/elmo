require 'test_helper'

# tests for submission of option sets via JSON
class OptionSetSubmissionTest < ActiveSupport::TestCase

  test "creating a multilevel option set via json should work" do
    # we use a mixture of existing and new options
    dog = Option.create(:name_en => 'Dog', :mission => get_mission)
    oak = Option.create(:name_en => 'Oak', :mission => get_mission)

    os = OptionSet.new.update_from_json!({
      'name' => 'foo',
      'mission' => get_mission,
      'multi_level' => true,
      'geographic' => false,
      '_option_levels' => [
        { 'en' => 'Kingdom', 'fr' => 'Royaume' },
        { 'en' => 'Species' }
      ],
      '_optionings' => [
        {
          'option' => {
            'name_translations' => {'en' => 'Animal'}
          },
          'optionings' => [
            {
              'option' => {
                'name_translations' => {'en' => 'Cat'}
              }
            },
            {
              'option' => {
                'id' => dog.id
              }
            }
          ]
        },
        {
          'option' => {
            'name_translations' => {'en' => 'Plant'}
          },
          'optionings' => [
            {
              'option' => {
                'name_translations' => {'en' => 'Tulip'}
              }
            },
            {
              'option' => {
                'id' => oak.id,
                # also change a name for this option
                'name_translations' => {'en' => 'White Oak'}
              }
            }
          ]
        }
      ]
    })

    os.reload

    assert_levels(%w(Kingdom Species), os)
    assert_options([['Animal', ['Cat', 'Dog']], ['Plant', ['Tulip', 'White Oak']]], os)
  end

  test 'updating a multilevel option set via JSON should work' do
    # create the standard animal/plant set
    os = FactoryGirl.create(:multilevel_option_set)

    # move pine from plant to animal, and move dog to top of animal list
    os.update_from_json!({
      '_option_levels' => [
        { 'en' => 'kingdom' },
        { 'en' => 'species' }
      ],
      '_optionings' => [
        {
          'id' => os.optionings[0].id,
          'option' => {
            'id' => os.optionings[0].option.id,
            'name_translations' => {'en' => 'animal'}
          },
          'optionings' => [
            {
              'id' => os.optionings[0].optionings[1].id,
              'option' => {
                'id' => os.optionings[0].optionings[1].option.id,
                'name_translations' => {'en' => 'dog'}
              }
            },
            {
              'id' => os.optionings[1].optionings[0].id,
              'option' => {
                'id' => os.optionings[1].optionings[0].option.id,
                'name_translations' => {'en' => 'pine'}
              }
            },
            {
              'id' => os.optionings[0].optionings[0].id,
              'option' => {
                'id' => os.optionings[0].optionings[0].option.id,
                'name_translations' => {'en' => 'cat'}
              }
            }
          ]
        },
        {
          'id' => os.optionings[1].id,
          'option' => {
            'id' => os.optionings[1].option.id,
            'name_translations' => {'en' => 'plant'}
          },
          'optionings' => [
            {
              'id' => os.optionings[1].optionings[1].id,
              'option' => {
                'id' => os.optionings[1].optionings[1].option.id,
                'name_translations' => {'en' => 'tulip'}
              }
            }
          ]
        }
      ]
    })

    assert_levels(%w(kingdom species), os)
    assert_options([['animal', ['dog', 'pine', 'cat']], ['plant', ['tulip']]], os)
  end

  test "moving option from level 2 to level 1 via JSON should work" do
    # create the standard animal/plant set
    os = FactoryGirl.create(:multilevel_option_set)

    # move pine from plant to root
    os.update_from_json!({
      '_option_levels' => [
        { 'en' => 'kingdom' },
        { 'en' => 'species' }
      ],
      '_optionings' => [
        {
          'id' => os.optionings[1].optionings[0].id,
          'option' => {
            'id' => os.optionings[1].optionings[0].option.id,
            'name_translations' => {'en' => 'pine'}
          }
        },
        {
          'id' => os.optionings[0].id,
          'option' => {
            'id' => os.optionings[0].option.id,
            'name_translations' => {'en' => 'animal'}
          },
          'optionings' => [
            {
              'id' => os.optionings[0].optionings[0].id,
              'option' => {
                'id' => os.optionings[0].optionings[0].option.id,
                'name_translations' => {'en' => 'cat'}
              }
            },
            {
              'id' => os.optionings[0].optionings[1].id,
              'option' => {
                'id' => os.optionings[0].optionings[1].option.id,
                'name_translations' => {'en' => 'dog'}
              }
            }
          ]
        },
        {
          'id' => os.optionings[1].id,
          'option' => {
            'id' => os.optionings[1].option.id,
            'name_translations' => {'en' => 'plant'}
          },
          'optionings' => [
            {
              'id' => os.optionings[1].optionings[1].id,
              'option' => {
                'id' => os.optionings[1].optionings[1].option.id,
                'name_translations' => {'en' => 'tulip'}
              }
            }
          ]
        }
      ]
    })

    assert_levels(%w(kingdom species), os)
    assert_options(['pine', ['animal', ['cat', 'dog']], ['plant', ['tulip']]], os)
  end

  test "moving option tree from level 1 to level 2 via JSON should work" do
    # create the standard animal/plant set
    os = FactoryGirl.create(:multilevel_option_set)

    # move animal tree to plant tree
    # and add new level and new option
    os.update_from_json!({
      '_option_levels' => [
        { 'en' => 'kingdom' },
        { 'en' => 'phylum' },
        { 'en' => 'species' }
      ],
      '_optionings' => [
        {
          'id' => os.optionings[1].id,
          'option' => {
            'id' => os.optionings[1].option.id,
            'name_translations' => {'en' => 'plant'}
          },
          'optionings' => [
            {
              'id' => os.optionings[1].optionings[1].id,
              'option' => {
                'id' => os.optionings[1].optionings[1].option.id,
                'name_translations' => {'en' => 'tulip'}
              }
            },
            {
              'id' => os.optionings[0].id,
              'option' => {
                'id' => os.optionings[0].option.id,
                'name_translations' => {'en' => 'animal'}
              },
              'optionings' => [
                {
                  'id' => os.optionings[0].optionings[0].id,
                  'option' => {
                    'id' => os.optionings[0].optionings[0].option.id,
                    'name_translations' => {'en' => 'cat'}
                  }
                },
                {
                  'option' => {
                    'name_translations' => {'en' => 'gnu'}
                  }
                },
                {
                  'id' => os.optionings[0].optionings[1].id,
                  'option' => {
                    'id' => os.optionings[0].optionings[1].option.id,
                    'name_translations' => {'en' => 'dog'}
                  }
                }
              ]
            },
            {
              'id' => os.optionings[1].optionings[0].id,
              'option' => {
                'id' => os.optionings[1].optionings[0].option.id,
                'name_translations' => {'en' => 'pine'}
              }
            }
          ]
        }
      ]
    })

    assert_levels(%w(kingdom phylum species), os)
    assert_options([['plant', ['tulip', ['animal', ['cat', 'gnu', 'dog']], 'pine']]], os)
  end

  # delete

  test "deleting single option via JSON should work" do
    # create the standard animal/plant set
    os = FactoryGirl.create(:multilevel_option_set)

    # delete dog option and move pine to animal subtree
    os.update_from_json!({
      '_option_levels' => [
        { 'en' => 'kingdom' },
        { 'en' => 'species' }
      ],
      '_optionings' => [
        {
          'id' => os.optionings[0].id,
          'option' => {
            'id' => os.optionings[0].option.id,
            'name_translations' => {'en' => 'animal'}
          },
          'optionings' => [
            {
              'id' => os.optionings[1].optionings[0].id,
              'option' => {
                'id' => os.optionings[1].optionings[0].option.id,
                'name_translations' => {'en' => 'pine'}
              }
            },
            {
              'id' => os.optionings[0].optionings[0].id,
              'option' => {
                'id' => os.optionings[0].optionings[0].option.id,
                'name_translations' => {'en' => 'cat'}
              }
            }
          ]
        },
        {
          'id' => os.optionings[1].id,
          'option' => {
            'id' => os.optionings[1].option.id,
            'name_translations' => {'en' => 'plant'}
          },
          'optionings' => [
            {
              'id' => os.optionings[1].optionings[1].id,
              'option' => {
                'id' => os.optionings[1].optionings[1].option.id,
                'name_translations' => {'en' => 'tulip'}
              }
            }
          ]
        },
        # here is the destroy request
        {
          'id' => old_id = os.optionings[0].optionings[1].id,
          '_destroy' => true
        }
      ]
    })

    assert_options([['animal', ['pine', 'cat']], ['plant', ['tulip']]], os)

    # ensure actually deleted
    assert_raise(ActiveRecord::RecordNotFound){Optioning.find(old_id)}
  end

  test "deleting option tree via JSON should work" do
    # create the standard animal/plant set
    os = FactoryGirl.create(:multilevel_option_set)

    # delete animal subtree but move cat to plants
    os.update_from_json!({
      '_option_levels' => [
        { 'en' => 'kingdom' },
        { 'en' => 'species' }
      ],
      '_optionings' => [
        {
          'id' => os.optionings[1].id,
          'option' => {
            'id' => os.optionings[1].option.id,
            'name_translations' => {'en' => 'plant'}
          },
          'optionings' => [
            {
              'id' => os.optionings[1].optionings[0].id,
              'option' => {
                'id' => os.optionings[1].optionings[0].option.id,
                'name_translations' => {'en' => 'pine'}
              }
            },
            {
              'id' => os.optionings[1].optionings[1].id,
              'option' => {
                'id' => os.optionings[1].optionings[1].option.id,
                'name_translations' => {'en' => 'tulip'}
              }
            },
            {
              'id' => os.optionings[0].optionings[0].id,
              'option' => {
                'id' => os.optionings[0].optionings[0].option.id,
                'name_translations' => {'en' => 'cat'}
              }
            }
          ]
        },
        # here is the destroy request. order shouldn't matter. we put the top level optioning first to test this.
        {
          'id' => os.optionings[0].id,
          '_destroy' => true
        },
        {
          'id' => os.optionings[0].optionings[1].id,
          '_destroy' => true
        }
      ]
    })

    assert_options([['plant', ['pine', 'tulip', 'cat']]], os)
  end

  test "deleting an option level should work" do
    # create the standard animal/plant set
    os = FactoryGirl.create(:multilevel_option_set)

    # delete dog option and move pine to animal subtree
    os.update_from_json!({
      '_option_levels' => [
        { 'en' => 'kingdom' }
      ],
      '_optionings' => [
        {
          'id' => os.optionings[0].id,
          'option' => {
            'id' => os.optionings[0].option.id,
            'name_translations' => {'en' => 'animal'}
          },
          'optionings' => []
        },
        {
          'id' => os.optionings[1].id,
          'option' => {
            'id' => os.optionings[1].option.id,
            'name_translations' => {'en' => 'plant'}
          },
          'optionings' => []
        },
        {
          'id' => old_id = os.optionings[0].optionings[0].id,
          '_destroy' => true
        },
        {
          'id' => old_id = os.optionings[0].optionings[1].id,
          '_destroy' => true
        },
        {
          'id' => old_id = os.optionings[1].optionings[0].id,
          '_destroy' => true
        },
        {
          'id' => old_id = os.optionings[1].optionings[1].id,
          '_destroy' => true
        }
      ]
    })

    assert_levels(%w(kingdom), os)
    assert_options(['animal', 'plant'], os)
  end

  test "downgrading to non-multilevel should work" do

    # create the standard animal/plant set
    os = FactoryGirl.create(:multilevel_option_set)

    # delete dog option and move pine to animal subtree
    os.update_from_json!({
      'multi_level' => false,
      '_option_levels' => [],
      '_optionings' => [
        {
          'id' => os.optionings[0].id,
          'option' => {
            'id' => os.optionings[0].option.id,
            'name_translations' => {'en' => 'animal'}
          },
          'optionings' => []
        },
        {
          'id' => os.optionings[1].id,
          'option' => {
            'id' => os.optionings[1].option.id,
            'name_translations' => {'en' => 'plant'}
          },
          'optionings' => []
        },
        {
          'id' => old_id = os.optionings[0].optionings[0].id,
          '_destroy' => true
        },
        {
          'id' => old_id = os.optionings[0].optionings[1].id,
          '_destroy' => true
        },
        {
          'id' => old_id = os.optionings[1].optionings[0].id,
          '_destroy' => true
        },
        {
          'id' => old_id = os.optionings[1].optionings[1].id,
          '_destroy' => true
        }
      ]
    })

    assert_equal([], os.option_levels)
    assert_equal(false, os.multi_level)
    assert_options(['animal', 'plant'], os)
  end

  test "updating non multilevel option set should work" do

    # create the standard yes/no
    os = FactoryGirl.create(:option_set)

    # add a new option
    os.update_from_json!({
      'multi_level' => false,
      '_option_levels' => [],
      '_optionings' => [
        {
          'id' => os.optionings[0].id,
          'option' => {
            'id' => os.optionings[0].option.id,
            'name_translations' => {'en' => 'Yes'}
          },
          'optionings' => []
        },
        {
          'id' => os.optionings[1].id,
          'option' => {
            'id' => os.optionings[1].option.id,
            'name_translations' => {'en' => 'No'}
          },
          'optionings' => []
        },
        {
          'option' => {
            'name_translations' => {'en' => 'Perhaps'}
          },
          'optionings' => []
        }
      ]
    })

    assert_equal([], os.option_levels)
    assert_equal(false, os.multi_level)
    assert_options(%w(Yes No Perhaps), os)
  end

  test "deleting from non multilevel option set should work" do

    # create the standard yes/no
    os = FactoryGirl.create(:option_set)

    # remove 'No' option
    os.update_from_json!({
      'multi_level' => false,
      '_option_levels' => [],
      '_optionings' => [
        {
          'id' => os.optionings[0].id,
          'option' => {
            'id' => os.optionings[0].option.id,
            'name_translations' => {'en' => 'Yes'}
          },
          'optionings' => []
        },
        {
          'id' => os.optionings[1].id,
          '_destroy' => true
        }
      ]
    })

    assert_equal([], os.option_levels)
    assert_equal(false, os.multi_level)
    assert_options(%w(Yes), os)
  end

  test "creating a multilevel option set in standard mode via json should work" do
    # we use a mixture of existing and new options
    dog = Option.create(:name_en => 'Dog', :is_standard => true)
    oak = Option.create(:name_en => 'Oak', :is_standard => true)

    os = OptionSet.new(:mission => nil, :is_standard => true).update_from_json!({
      'name' => 'foo',
      'mission' => get_mission,
      'multi_level' => true,
      'geographic' => false,
      '_option_levels' => [
        { 'en' => 'Kingdom', 'fr' => 'Royaume' },
        { 'en' => 'Species' }
      ],
      '_optionings' => [
        {
          'option' => {
            'name_translations' => {'en' => 'Animal'}
          },
          'optionings' => [
            {
              'option' => {
                'name_translations' => {'en' => 'Cat'}
              }
            },
            {
              'option' => {
                'id' => dog.id
              }
            }
          ]
        },
        {
          'option' => {
            'name_translations' => {'en' => 'Plant'}
          },
          'optionings' => [
            {
              'option' => {
                'name_translations' => {'en' => 'Tulip'}
              }
            },
            {
              'option' => {
                'id' => oak.id,
                # also change a name for this option
                'name_translations' => {'en' => 'White Oak'}
              }
            }
          ]
        }
      ]
    })

    os.reload

    assert_levels(%w(Kingdom Species), os)
    assert_options([['Animal', ['Cat', 'Dog']], ['Plant', ['Tulip', 'White Oak']]], os)
  end


  private

    # checks that option set levels matches the given names
    def assert_levels(expected, os)
      assert_equal(expected, os.option_levels.map(&:name_en))

      # check that all have mission, standard, and correct option set reference
      assert_equal([os.mission], os.option_levels.map(&:mission).uniq)
      assert_equal([os.is_standard?], os.option_levels.map(&:is_standard?).uniq)
      assert_equal([os], os.option_levels.map(&:option_set).uniq)

      # check for correct sequential ranks
      assert_equal((1..os.option_levels.size).to_a, os.option_levels.map(&:rank), 'option level ranks not sequential')
    end

    # checks that option set matches the given structure
    # recursive method
    # for expected array, interior nodes are arrays with array[0] = label, array[1] = children
    # leaf nodes are strings
    # for root node, only array[1] is passed
    # runs twice, once before save, once after
    def assert_options(expected, os)
      # assert once
      assert_options_once(expected, os)

      # now save the option set and assert again
      os.save!
      os.reload
      assert_options_once(expected, os)
    end

    def assert_options_once(expected, os, node = nil, depth = nil, parent = nil)
      if node.nil?
        assert_options_once([nil, expected], os, os, 0, nil)
      else
        assert_equal(os.is_standard?, node.is_standard?, 'standard flag did not match')

        unless node.is_a?(OptionSet)
          # ensure correct option set
          assert_equal(os, node.option_set, 'incorrect option set')

          # ensure correct option level
          if os.multi_level?
            assert_equal(os.option_levels[depth - 1], node.option_level, 'incorrect option level exp')
          else
            assert_nil(node.option_level)
          end

          # ensure correct parent
          assert_equal(parent, node.parent, 'incorrect parent')

          # ensure correct standard flag for option
          assert_equal(os.is_standard?, node.option.is_standard?, 'standard flag did not match on option')
        end

        # if expecting interior node
        if expected.is_a?(Array)
          # ensure node name is correct
          assert_equal(expected[0], node.option.name_en) unless expected[0].nil?

          # ensure correct number of children
          assert_equal(expected[1].size, node.optionings.size, 'incorrect number of children')

          # ensure correct sequential ranks
          assert_equal((1..node.optionings.size).to_a, node.optionings.map(&:rank), 'optioning ranks not sequential')

          # ensure children are correct (recursive step)
          expected[1].each_with_index do |e, idx|
            assert_options_once(e, os, node.optionings[idx], depth + 1, node.is_a?(OptionSet) ? nil : node)
          end

        # else, expecting leaf
        else
          assert_equal(expected, node.option.name_en)
          assert_equal([], node.optionings, 'should be leaf')
        end
      end
    end
end