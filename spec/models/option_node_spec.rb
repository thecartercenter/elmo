require 'spec_helper'

describe OptionNode do
  include OptionNodeSupport

  describe 'destroy' do
    before do
      @node = create(:option_node_with_grandchildren)
      @option = @node.children[0].option
      @node.children[0].destroy
    end

    it 'should not destroy option' do
      expect(Option.exists?(@option)).to be_truthy
    end
  end

  describe 'updating without hash' do
    before do
      @node = create(:option_node_with_grandchildren)
      @other_option = create(:option)
      @node.c[0].update_attributes!(option: @other_option)
    end

    it 'should not destroy children' do
      expect(@node.c[0].children.size).to eq 2
    end
  end

  describe 'option_level' do
    before do
      @node = create(:option_node_with_grandchildren)
      allow_message_expectations_on_nil # Since we want to set expectations on subnode.option_set, which is nil.
    end

    it 'should be nil for root' do
      expect(@node.level).to be_nil
    end

    it 'should be correct for first level' do
      subnode = @node.c[0]
      expect(subnode.option_set).to receive(:try).with(:level, 1).and_return(double(:name => 'Foo'))
      expect(subnode.level.name).to eq 'Foo'
    end

    it 'should be correct for second level' do
      subnode = @node.c[0].c[0]
      expect(subnode.option_set).to receive(:try).with(:level, 2).and_return(double(:name => 'Bar'))
      expect(subnode.level.name).to eq 'Bar'
    end

    it 'might be nil for first level' do
      subnode = @node.c[0]
      expect(subnode.option_set).to receive(:try).with(:level, 1).and_return(nil)
      expect(subnode.level).to be_nil
    end
  end

  describe 'creating single level from hash' do
    before do
      # we use a mixture of existing and new options
      @dog = create(:option, name_en: 'Dog')
      @node = OptionNode.create!(
        'mission_id' => get_mission.id,
        'option' => nil,
        'children_attribs' => [
          { 'option_attribs' => { 'name_translations' => {'en' => 'Cat'} } },
          { 'option_attribs' => { 'id' => @dog.id, 'name_translations' => {'en' => 'Dog'} } }
        ]
      )
    end

    it 'should be correct' do
      expect_node(['Cat', 'Dog'])
    end
  end

  describe 'creating multilevel from hash' do
    before do
      # we use a mixture of existing and new options
      @dog = create(:option, name_en: 'Dog')
      @oak = create(:option, name_en: 'Oak')
      @node = OptionNode.create!(
        'option' => nil,
        'mission_id' => get_mission.id,
        'children_attribs' => [{
          'option_attribs' => { 'name_translations' => {'en' => 'Animal'} },
          'children_attribs' => [
            { 'option_attribs' => { 'name_translations' => {'en' => 'Cat'} } },
            { 'option_attribs' => { 'id' => @dog.id } } # Existing option
          ]
        }, {
          'option_attribs' => { 'name_translations' => {'en' => 'Plant'} },
          'children_attribs' => [
            { 'option_attribs' => { 'name_translations' => {'en' => 'Tulip'} } },
            { 'option_attribs' => { 'id' => @oak.id, 'name_translations' => {'en' => 'White Oak'} } } # also change a name for this option
          ]
        }]
      )
    end

    it 'should be correct' do
      expect_node([['Animal', ['Cat', 'Dog']], ['Plant', ['Tulip', 'White Oak']]])
    end
  end

  describe 'updating from hash with no changes' do
    before do
      @node = create(:option_node_with_grandchildren)
      @node.update_attributes!(no_change_changeset(@node))
    end

    it 'should still be correct' do
      expect_node([['Animal', ['Cat', 'Dog']], ['Plant', ['Tulip', 'Oak']]])
    end

    it 'should not cause ranks to change' do
      expect(@node.ranks_changed?).to eq false
    end

    it 'should cause options_added? to be false' do
      expect(@node.options_added?).to eq false
    end

    it 'should cause options_removed? to be false' do
      expect(@node.options_removed?).to eq false
    end
  end

  describe 'updating from hash with changes' do
    before do
      @node = create(:option_node_with_grandchildren)
      @node.update_attributes!(standard_changeset(@node))
    end

    it 'should be correct' do
      expect_node([['Animal', ['Doge']], ['Plant', ['Cat', 'Tulipe']]])
    end

    it 'should cause ranks_changed? to become true' do
      expect(@node.ranks_changed?).to eq true
    end

    it 'should cause options_added? to be true' do
      expect(@node.options_added?).to eq true
    end

    it 'should cause options_removed? to be true' do
      expect(@node.options_removed?).to eq true
    end
  end

  describe 'adding an option via hash' do
    before do
      @node = create(:option_node_with_grandchildren)
      @node.update_attributes!(additive_changeset(@node))
    end

    it 'should be correct' do
      expect_node([['Animal', ['Cat', 'Dog', 'Ocelot']], ['Plant', ['Tulip', 'Oak']]])
    end

    it 'should cause ranks_changed? to be false' do
      expect(@node.ranks_changed?).to eq false
    end

    it 'should cause options_added? to be true' do
      expect(@node.options_added?).to eq true
    end

    it 'should cause options_removed? to be false' do
      expect(@node.options_removed?).to eq false
    end
  end

  describe 'destroying subtree and adding new subtree' do
    before do
      @node = create(:option_node_with_grandchildren)
      @node.update_attributes!('children_attribs' => [
        no_change_changeset(@node)['children_attribs'][0],
        {
          'option_attribs' => { 'name_translations' => {'en' => 'Laser'} },
          'children_attribs' => [
            {
              'option_attribs' => { 'name_translations' => {'en' => 'Green'} }
            },
            {
              'option_attribs' => { 'name_translations' => {'en' => 'Red'} }
            }
          ]
        }]
      )
    end

    it 'should be correct' do
      expect_node([['Animal', ['Cat', 'Dog']], ['Laser', ['Green', 'Red']]])
    end

    it 'should not cause ranks_changed? to become true' do
      expect(@node.ranks_changed?).to eq false
    end
  end

  describe 'destroying all' do
    before do
      @node = create(:option_node_with_grandchildren)

      @node.update_attributes!('children_attribs' => [])
    end

    it 'should be correct' do
      expect_node([])
    end
  end

  describe 'has_grandchildren?' do
    it 'should return false for single level node' do
      expect(create(:option_node_with_children).has_grandchildren?).to eq false
    end

    it 'should return true for multi level node' do
      expect(create(:option_node_with_grandchildren).has_grandchildren?).to eq true
    end
  end

  describe 'child_options' do
    it 'should return child options in sorted order' do
      node = create(:option_node_with_grandchildren)
      expect(node.child_options.map(&:name)).to eq %w(Animal Plant)
    end
  end

  describe 'options_for_node' do
    it 'should return correct options for various nodes' do
      node = create(:option_node_with_great_grandchildren)
      expect(node.options_for_node([]).map(&:name)).to eq %w(Animal Plant)
      expect(node.options_for_node([node.c[1].option_id]).map(&:name)).to eq %w(Tree Flower)
    end
  end

  describe 'option_path_to_rank_path' do
    before do
      @node = create(:option_node_with_grandchildren)
    end

    it 'should be correct for partial path' do
      expect(@node.option_path_to_rank_path([@node.c[0].option])).to eq [1]
    end

    it 'should be correct for full path' do
      expect(@node.option_path_to_rank_path([@node.c[1].option, @node.c[1].c[0].option])).to eq [2,1]
    end

    it 'should raise error for invalid path' do
      expect{@node.option_path_to_rank_path([create(:option)])}.to raise_error(ArgumentError)
    end
  end

  describe 'rank_path_to_option_path' do
    before do
      @node = create(:option_node_with_grandchildren)
    end

    it 'should be correct for partial path' do
      expect(@node.rank_path_to_option_path([2])).to eq [@node.c[1].option]
    end

    it 'should be correct for full path' do
      expect(@node.rank_path_to_option_path([2,1])).to eq [@node.c[1].option, @node.c[1].c[0].option]
    end

    it 'should raise error for invalid path' do
      expect{@node.rank_path_to_option_path([1,4])}.to raise_error(ArgumentError)
    end
  end
end
