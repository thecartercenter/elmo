# frozen_string_literal: true

# DEPRECATED: Model-related display logic should move to a decorator.
module SmsHelper
  MAX_RECIPS_TO_SHOW = 3

  def sms_messages_index_fields
    %w[type time to from body adapter_name]
  end

  def format_sms_messages_field(sms, field)
    case field
    when "type" then sms.type.split("::")[1]
    when "time"
      if sms.sent_at <= sms.created_at - 1.minute
        time_diff = time_diff(sms.sent_at, sms.created_at)
        t("sms.timestamp_with_diff_html", time: l(sms.created_at), time_diff: time_diff)
      else
        l(sms.created_at)
      end
    when "to" then
      recips = safe_join(
        sms.recipient_hashes(max: MAX_RECIPS_TO_SHOW).map { |r| user_with_phone(r[:user], r[:phone]) },
        "<br/>".html_safe
      )
      extra_recipients = sms.recipient_count - MAX_RECIPS_TO_SHOW
      recips << (extra_recipients.positive? ? t("sms.extra_recipients_html", count: extra_recipients) : "")
      recips
    when "from"
      user_with_phone(sms.sender, sms.from)
    when "body" then
      output = []
      output << tag.span(sms.body)
      if sms.reply_error_message
        output << tag.div(
          "#{I18n.t('sms.error')}: #{I18n.t('sms.when_sending_reply')}: #{sms.reply_error_message}",
          class: "error-msg"
        )
      end
      safe_join(output)
    else
      sms.send(field)
    end
  end

  # Constructs html to show a user with a phone number for use in the SMS log.
  # Phone may only be nil if the user is the dummy ELMO user for incoming messages.
  def user_with_phone(user, phone)
    output = "".html_safe

    if user == Sms::SiteUser.instance
      output << user.name
      if phone.present?
        output << " "
        output << tag.small("(#{phone})")
      end
    elsif user
      output << link_to(user.name, user_path(user))
      output << " "
      output << tag.small("(#{phone})")
    else
      output << phone
    end

    output
  end

  def time_diff(start_time, end_time)
    seconds_diff = (start_time - end_time).to_i.abs

    hours = seconds_diff / 3600
    seconds_diff -= hours * 3600

    minutes = seconds_diff / 60

    str = +""
    str << "#{hours}h" if hours.positive?
    str << "#{minutes}m"
    str
  end
end
