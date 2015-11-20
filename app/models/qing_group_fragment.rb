# This class is used to represent a fragment of a QingGroup.
# ODK has issues showing a multilevel question inside a group,
# so we split up a group that has a multilevel question on it
# and remove it from the group to send it for ODK.
#
# Instances of this hold the other questions on the group that
# weren't a multilevel question.
#
# See QingGroupOdkPartitioner for more details.
class QingGroupFragment
  include Translatable

  attr_accessor :children, :qing_group

  delegate :hidden, :id, :group_name, :group_hint, :group_name_translations,
    :group_hint_translations, :repeats, to: :qing_group

  def initialize(qing_group)
    self.qing_group = qing_group
    self.children = ActiveSupport::OrderedHash.new
  end

  def multi_level?
    children.keys.first.multi_level?
  end

end
