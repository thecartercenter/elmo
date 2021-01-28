# frozen_string_literal: true

class CopyActiveStorageFromPaperclipLocal < ActiveRecord::Migration[6.0]
  def up
    if Rails.configuration.active_storage.service == :local
      puts "Using LOCAL storage."
      copy_all_local
    else
      # Prepare for the next migration when the copy will actually happen.
      puts "Using CLOUD storage."

      unless ActiveRecord::Base.connection.column_exists?(:operations, :attachment_legacy_url)
        add_column :operations, :attachment_legacy_url, :string
        add_column :saved_uploads, :file_legacy_url, :string
        add_column :questions, :media_prompt_legacy_url, :string
        add_column :media_objects, :item_legacy_url, :string
        add_column :responses, :odk_xml_legacy_url, :string

        Operation.reset_column_information
        SavedUpload.reset_column_information
        Question.reset_column_information
        Media::Object.reset_column_information
        Response.reset_column_information
      end

      save_legacy_urls
    end
  end

  def down
    return unless ActiveRecord::Base.connection.column_exists?(:operations, :attachment_legacy_url)
    remove_column :operations, :attachment_legacy_url
    remove_column :saved_uploads, :file_legacy_url
    remove_column :questions, :media_prompt_legacy_url
    remove_column :media_objects, :item_legacy_url
    remove_column :responses, :odk_xml_legacy_url
  end
end

NEMO_ATTACHMENTS = [
  [Operation, "attachment"],
  [SavedUpload, "file"],
  [Question, "media_prompt"],
  [Media::Object, "item"],
  [Response, "odk_xml"]
].freeze

# Expectation: ActiveStorage syntax is NOT yet migrated
# (e.g. has_attached_file, NOT has_one_attached).
#
# By default, Paperclip looks like this:
# public/system/users/avatars/000/000/004/original/the-mystery-of-life.png
#
# And ActiveStorage looks like this:
# storage/xM/RX/xMRXuT6nqpoiConJFQJFt6c9 (for local storage).
#
# From https://github.com/thoughtbot/paperclip/blob/master/MIGRATING.md
def copy_all_local
  ActiveStorage::Attachment.order(:id).find_each do |attachment|
    name = attachment.name
    source = attachment.record.send(name).path
    dest_dir = File.join("storage", attachment.blob.key.first(2), attachment.blob.key.first(4).last(2))
    dest = File.join(dest_dir, attachment.blob.key)

    puts "Copying #{source}"
    puts "  to #{dest}" if ENV["VERBOSE"]
    FileUtils.mkdir_p(dest_dir)
    FileUtils.cp(source, dest)
  end
end

# Save Paperclip URLs so that we can use them in the next migration
# after ActiveStorage syntax is in use.
def save_legacy_urls
  NEMO_ATTACHMENTS.each do |pair|
    relation, title = pair
    relation = relation.where.not("#{title}_file_size": nil)

    puts "Saving #{relation.count} #{relation.name} #{title.pluralize}..."
    relation.order(:created_at).find_each do |record|
      url = record.send(title).url
      puts "Saving #{record.id}: #{url}" if ENV["VERBOSE"]
      record.update_attribute("#{title}_legacy_url", url)
    end
  end
end
