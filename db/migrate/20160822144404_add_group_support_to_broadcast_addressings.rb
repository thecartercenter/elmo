class AddGroupSupportToBroadcastAddressings < ActiveRecord::Migration
  def up
    # Might as well do this, should have been done before.
    execute("DELETE FROM broadcast_addressings WHERE user_id IS NULL OR broadcast_id IS NULL")
    change_column_null :broadcast_addressings, :user_id, false
    change_column_null :broadcast_addressings, :broadcast_id, false

    rename_column :broadcast_addressings, :user_id, :addressee_id
    add_column :broadcast_addressings, :addressee_type, :string

    execute("UPDATE broadcast_addressings SET addressee_type = 'User'")

    change_column_null :broadcast_addressings, :addressee_type, false
  end
end
