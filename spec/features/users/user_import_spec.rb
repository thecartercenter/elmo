# frozen_string_literal: true

require "rails_helper"

feature "user import", js: true do
  include_context "dropzone"

  let(:admin) { create(:admin) }
  let(:mission) { get_mission }

  before do
    login(admin)
  end

  scenario "happy path" do
    visit("/en/m/#{mission.compact_name}/user-imports/new")
    drop_in_dropzone(user_import_fixture("varying_info.xlsx").path)
    click_button("Import")
    expect(page).to have_content("User import queued")
    Delayed::Worker.new.work_off
    click_link("operations panel")
    click_on("User import from varying_info.xlsx")
    expect(page).to have_content("Status Success")
  end
end
