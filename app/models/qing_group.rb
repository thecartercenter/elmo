class QingGroup < FormItem
  include Translatable

  translates :group_name, :group_hint

  replicable child_assocs: :children, backward_assocs: :form, dont_copy: [:form_id]

  alias_method :c, :sorted_children

  def child_groups
    children.where(type: "QingGroup")
  end

end
