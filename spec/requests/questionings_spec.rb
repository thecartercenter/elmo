require "spec_helper"

# Using request spec b/c Authlogic won't work with controller spec
describe "questionings", type: :request do
  let(:user) { create(:user, role_name: "coordinator") }

  before do
    login(user)
  end

  describe "update" do
    context "when published" do
      let(:form) { create(:form, :published, question_types: %w(text text)) }
      let(:qing) { form.questionings.first }

      it "changing name should succeed" do
        put(questioning_path(qing, mode: "m", mission_name: get_mission.compact_name),
          "questioning" => {
            "question_attributes" => {
              "id" => qing.question_id,
              "name_en" => "Foo"
            }
          }
        )
        expect(response).to be_redirect
        expect(qing.reload.name_en).to eq("Foo")
      end

      it "changing required flag should be unauthorized" do
        put(questioning_path(qing, mode: "m", mission_name: get_mission.compact_name),
          "questioning" => {"required" => "1"})
        expect(response).to redirect_to(unauthorized_path)
      end

      it "changing hidden flag should be unauthorized" do
        put(questioning_path(qing, mode: "m", mission_name: get_mission.compact_name),
          "questioning" => {"hidden" => "1"})
        expect(response).to redirect_to(unauthorized_path)
      end

      it "changing condition should be unauthorized" do
        put(questioning_path(qing, mode: "m", mission_name: get_mission.compact_name),
          "questioning" => {
            "display_conditions_attributes" => [{
              "ref_qing_id" => form.c[0].id,
              "op" => "eq",
              "value" => "foo"
            }]
          }
        )
        expect(response).to redirect_to(unauthorized_path)
      end
    end
  end

  describe "condition_form_data" do
    let(:form) { create(:form, :published, question_types: %w(integer text select_one integer text)) }
    let(:qing) { form.c[3] }
    let(:expected_ref_qing_options) { form.c[0..2].map { |q| {  id: q.id, code: q.question.code, rank: q.rank, full_dotted_rank: q.full_dotted_rank } } }

    context "without ref_qing_id" do
      it "returns json with ref qing id options, no operator options, and no value options" do
        expected = {
          id: nil,
          ref_qing_id: nil,
          op: nil,
          value: nil,
          option_node: nil,
          form_id: form.id,
          conditionable_id: qing.id,
          operator_options: [],
          refable_qings: expected_ref_qing_options
        }.to_json
        get "/en/m/#{get_mission.compact_name}/questionings/condition-form",{
          ref_qing_id: nil,
          form_id: form.id,
          conditionable_id: qing.id
        }
        expect(response).to have_http_status(200)
        expect(response.body).to eq expected
      end
    end

    context "with ref_qing_id" do
      it "returns json with operator options" do
        expected_operator_options = [
          {name:"is equal to", id:"eq" },
          {name:"is less than", id:"lt" },
          {name:"is greater than", id:"gt" },
          {name:"is less than or equal to", id:"leq" },
          {name:"is greater than or equal to", id:"geq" },
          {name:"is not equal to", id:"neq" }
        ]
        expected = {
          id: nil,
          ref_qing_id: form.c[0].id,
          op: nil,
          value: nil,
          option_node: nil,
          form_id: form.id,
          conditionable_id: qing.id,
          operator_options: expected_operator_options,
          refable_qings: expected_ref_qing_options
        }.to_json
        get "/en/m/#{get_mission.compact_name}/questionings/condition-form",
          {
            ref_qing_id: form.c[0].id,
            form_id: form.id,
            conditionable_id: qing.id
          }
        expect(response).to have_http_status(200)
        expect(response.body).to eq expected
      end

      context " text value exists" do
        let(:condition) { create(:condition, conditionable: qing, ref_qing: form.c[1], value: "Test") } #ref_qing: form.c[1], op: "eq", value: "Test"}

        it "returns text value" do
          expected_operator_options = [
            {name:"is equal to", id:"eq" },
            {name:"is not equal to", id:"neq" }
          ]
          expected = {
            id: condition.id,
            ref_qing_id: condition.ref_qing.id,
            op: condition.op,
            value: "Test",
            option_node: nil,
            form_id: form.id,
            conditionable_id: qing.id,
            operator_options: expected_operator_options,
            refable_qings: expected_ref_qing_options
          }.to_json
          get "/en/m/#{get_mission.compact_name}/questionings/condition-form",
            {
              condition_id: condition.id,
              ref_qing_id: form.c[1].id,
              form_id: form.id,
              conditionable_id: qing.id
            }
          expect(response).to have_http_status(200)
          expect(response.body).to eq expected
        end
      end

      context "option node value exists" do
        let(:condition) { create(:condition, conditionable: qing, ref_qing: form.c[2], value: nil) }

        it "returns text value" do
          expected_operator_options = [
            {name:"is equal to", id:"eq" },
            {name:"is not equal to", id:"neq" }
          ]
          expected = {
            id: condition.id,
            ref_qing_id: condition.ref_qing.id,
            op: condition.op,
            value: nil,
            option_node: { node_id: form.c[2].option_set.c[0].id, set_id: form.c[2].option_set.id },
            form_id: form.id,
            conditionable_id: qing.id,
            operator_options: expected_operator_options,
            refable_qings: expected_ref_qing_options
          }.to_json
          get "/en/m/#{get_mission.compact_name}/questionings/condition-form",
            {
              condition_id: condition.id,
              ref_qing_id: form.c[2].id,
              form_id: form.id,
              conditionable_id: qing.id
            }
          expect(response).to have_http_status(200)
          expect(response.body).to eq expected
        end
      end
    end
  end
end
