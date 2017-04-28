require "spec_helper"
require "support/media_spec_helpers"

describe "odk media submissions", type: :request, clean_with_truncation: true do
  include ODKSubmissionSupport

  let(:user) { create(:user, role_name: "observer") }
  let(:form) { create(:form, :published, :with_version, version: "abc", question_types: %w(text image)) }
  let(:mission) { form.mission }

  context "with single part" do
    it "should successfully process the submission" do
      image = fixture_file_upload(media_fixture("images/the_swing.jpg"), "image/jpeg")
      submission_path = Rails.root.join("spec", "expectations", "odk", "responses", "single_part_media.xml")
      submission_file = fixture_file_upload(submission_path, "text/xml")

      post submission_path(mission), { xml_submission_file: submission_file, "the_swing.jpg" => image },
        "HTTP_AUTHORIZATION" => encode_credentials(user.login, test_password)
      expect(response).to have_http_status 201

      form_response = Response.last
      expect(form_response.form).to eq form
      form_response.answers.each do |answer|
        qing = answer.questioning
        expect(answer.media_object).to be_present if qing.qtype.multimedia?
      end
    end
  end

  context "with multiple parts" do
    let(:form) { create(:form, :published, :with_version, version: "abc", question_types: %w(text image sketch)) }

    it "should successfully process the submission" do
      image = fixture_file_upload(media_fixture("images/the_swing.jpg"), "image/jpeg")
      image2 = fixture_file_upload(media_fixture("images/the_swing.jpg"), "image/jpeg")

      submission_path = Rails.root.join("spec", "expectations", "odk", "responses", "multiple_part_media.xml")
      submission_file = fixture_file_upload(submission_path, "text/xml")

      # Submit first part
      post submission_path(mission), {
        xml_submission_file: submission_file,
        "the_swing.jpg" => image,
        "*isIncomplete*" => "yes"},
        "HTTP_AUTHORIZATION" => encode_credentials(user.login, test_password)
      expect(response).to have_http_status 201
      expect(Response.count).to eq 1

      form_response = Response.last
      expect(form_response.odk_hash).to be_present

      # Submit second part
      post submission_path(mission), {
        xml_submission_file: submission_file,
        "another_swing.jpg" => image2 },
        "HTTP_AUTHORIZATION" => encode_credentials(user.login, test_password)

      expect(response).to have_http_status 201
      expect(Response.count).to eq 1

      form_response = Response.last
      expect(form_response.odk_hash).to_not be_present

      expect(form_response.form).to eq form
      expect(form_response.answers.count).to eq 3

      form_response.answers.each do |answer|
        qing = answer.questioning
        expect(answer.media_object).to be_present if qing.qtype.multimedia?
      end
    end
  end
end
