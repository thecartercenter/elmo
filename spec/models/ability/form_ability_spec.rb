# frozen_string_literal: true

require "rails_helper"

describe "abilities for forms" do
  include_context "ability"

  let(:object) { form }
  let(:all) do
    %i[add_questions change_status clone destroy download remove_questions reorder_questions show update]
  end

  context "for admin" do
    let(:user) { create(:user, admin: true) }
    let(:ability) { Ability.new(user: user, mode: "admin") }

    context "when standard" do
      let(:form) { create(:form, :standard, question_types: %w[text]) }
      let(:permitted) { %i[show clone update add_questions remove_questions reorder_questions destroy] }
      it_behaves_like "has specified abilities"
    end
  end

  context "for coordinator" do
    let(:user) { create(:user, role_name: "coordinator") }
    let(:ability) { Ability.new(user: user, mode: "mission", mission: get_mission) }

    it "should be able to create and index" do
      %i[create index].each { |op| expect(ability).to be_able_to(op, Form) }
    end

    context "when draft" do
      let(:form) { create(:form, question_types: %w[text]) }

      context "without responses" do
        let(:permitted) do
          %i[show update change_status clone add_questions remove_questions reorder_questions destroy]
        end
        it_behaves_like "has specified abilities"
      end

      context "with responses" do
        let(:permitted) do
          %i[show update change_status clone add_questions remove_questions reorder_questions]
        end

        before do
          create(:response, form: form, answer_values: ["foo"])
          form.reload
        end

        it_behaves_like "has specified abilities"
      end
    end

    context "when live" do
      let(:form) { create(:form, :live, question_types: %w[text]) }
      let(:permitted) { %i[show update change_status download clone] }
      it_behaves_like "has specified abilities"
    end

    context "when standard" do
      let(:form) { create(:form, :standard, question_types: %w[text]) }
      let(:permitted) { [] }
      it_behaves_like "has specified abilities"
    end

    context "when unpublished std copy" do
      let(:std) { create(:form, :standard, question_types: %w[text]) }
      let(:form) { std.replicate(mode: :to_mission, dest_mission: get_mission) }
      let(:permitted) do
        %i[show update change_status clone add_questions remove_questions reorder_questions destroy]
      end
      it_behaves_like "has specified abilities"
    end
  end
end
