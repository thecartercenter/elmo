# frozen_string_literal: true

class AddOdkHashToResponses < ActiveRecord::Migration[4.2]
  def change
    add_column :responses, :odk_hash, :string
    add_index :responses, %i[form_id odk_hash], unique: true
  end
end
