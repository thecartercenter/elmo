require 'spec_helper'
require 'xml'

# We need to clean with truncation here b/c we use hard coded id's in expectation.
describe 'form rendering for odk', clean_with_truncation: true do
  before do
    @user = create(:user)
    login(@user)
  end

  context 'sample form' do
    before do
      @form = create(:form, question_types: %w(select_one select_one integer select_multiple integer))

      # Make the second question use the grandchildren option set, but make that option set uneven.
      @large_opt_set = create(:option_set, super_multi_level: true)
      @large_opt_set.root_node.c[0].c[0].children.each{ |c| c.destroy }
      @form.questions[1].update_attributes!(option_set: @large_opt_set)

      # Hidden question should not be included, even if required.
      @form.questionings[4].update_attributes!(hidden: true, required: true)

      @form.publish!
      get(form_path(@form, format: :xml))
    end

    it 'should render proper xml' do
      expect(response).to be_success

      # Parse the XML and tidy.
      doc = XML::Parser.string(response.body, options: XML::Parser::Options::NOBLANKS).parse
      expect(doc.to_s).to eq File.read(File.expand_path('../../expectations/sample_form_odk.xml', __FILE__))
    end
  end

  context 'group form' do
    before do
      @form = create(:form, question_types: [['text', 'text', 'text']])
      @form.publish!
      get(form_path(@form, format: :xml))
    end

    it 'should render items in the group' do
      expect(response).to be_success
      doc = XML::Parser.string(response.body, options: XML::Parser::Options::NOBLANKS).parse
      expect(doc.to_s).to eq File.read(File.expand_path('../../expectations/group_form_odk.xml', __FILE__))
    end
  end

  context 'grid form' do
    before do
      @form = create(:form, question_types: [['select_one', 'select_one']])
      @form.c[0].c[1].update_attributes(option_set: @form.c[0].c[0].option_set)
      @form.publish!
      get(form_path(@form, format: :xml))
    end

    it 'should render items in the grid' do
      expect(response).to be_success
      doc = XML::Parser.string(response.body, options: XML::Parser::Options::NOBLANKS).parse
      expect(doc.to_s).to eq File.read(File.expand_path('../../expectations/grid_form_odk.xml', __FILE__))
    end
  end
end
