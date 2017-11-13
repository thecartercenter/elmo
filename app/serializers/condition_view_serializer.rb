class ConditionViewSerializer < ActiveModel::Serializer
  attributes :id, :ref_qing_id, :op, :value, :form_id, :questioning_id, :refable_qing_options, :operator_options, :value_options

  def questioning_id
    object.questioning_id
  end

  def refable_qing_options
    object.refable_qings.map { |q| {code: q.question.code, rank: q.full_dotted_rank, id: q.id} }
  end

  def operator_options
    object.applicable_operator_names.map { |n| {name: I18n.t("condition.operators.#{n}"), id: n} }
  end

  def value_options
    nil
  end
end
