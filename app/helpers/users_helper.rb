module UsersHelper
  def users_index_links(users)
    links = []
    links << batch_op_link(:name => t("broadcast.send_broadcast"), :path => new_with_users_broadcasts_path) if can?(:create, Broadcast)
    links << batch_op_link(:name => t("user.export_vcard"), :path => export_users_path(:format => :vcf)) if can?(:export, User)
    links << create_link(User) if can?(:create, User)
    links << link_to(t("user.create_multiple"), new_user_batch_path) if can?(:create, UserBatch)
    links
  end

  def users_index_fields
    f = %w(name login email phone phone2 admin)
    f << (admin_mode? ? 'latest_mission' : 'role')
    f << 'actions'
    f
  end

  def format_users_field(user, field)
    case field
    when "name" then link_to(user.name, user_path(user))
    when "email" then mail_to(user.email)
    when "latest_mission" then (lm = user.latest_mission) ? lm.name : "[#{t('common.none')}]"
    when "role" then t(user.roles[current_mission], :scope => :role)
    when "admin" then user.admin? ? t('common._yes') : ''
    when "actions" then action_links(user, :obj_name => user.name)
    else user.send(field)
    end
  end

  def assignment_errors
    e = []
    e << User.human_attribute_name(:role) + ' ' + @user.errors[:'assignments.role'].first unless @user.errors[:'assignments.role'].empty?
    e << User.human_attribute_name(:mission_id) + ' ' + @user.errors[:'assignments.mission'].first unless @user.errors[:'assignments.mission'].empty?
    e
  end
end
