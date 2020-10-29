# frozen_string_literal: true

class CreateUserGroupAssignments < ActiveRecord::Migration[4.2]
  def change
    create_table :user_group_assignments do |t|
      t.references :user, index: true, foreign_key: true, null: false
      t.references :user_group, index: true, foreign_key: true, null: false

      t.timestamps null: false
    end
    add_index :user_group_assignments, %i[user_id user_group_id], unique: true
  end
end
