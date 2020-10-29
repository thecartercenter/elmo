# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: saved_uploads
#
#  id                :uuid             not null, primary key
#  file_content_type :string           not null
#  file_file_name    :string           not null
#  file_file_size    :integer          not null
#  file_updated_at   :datetime         not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# rubocop:enable Layout/LineLength

# A model for a generic file upload, managed by Paperclip
class SavedUpload < ApplicationRecord
  has_attached_file :file
  validates_attachment_presence :file
  do_not_validate_attachment_file_type :file

  scope :old, -> { where("created_at < ?", 30.days.ago) }

  def self.cleanup_old_uploads
    old.destroy_all
  end
end
