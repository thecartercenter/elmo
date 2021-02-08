# frozen_string_literal: true

class MoveDefaultSettingsToRootConfig < ActiveRecord::Migration[6.0]
  def up
    return unless configatron.key?(:default_settings)
    root_setting = Setting.root
    root_setting.default_outgoing_sms_adapter = fetch_default_setting(:outgoing_sms_adapter)
    root_setting.twilio_account_sid = fetch_default_setting(:twilio_account_sid)
    root_setting.twilio_auth_token = fetch_default_setting(:twilio_auth_token)
    root_setting.twilio_phone_number = fetch_default_setting(:twilio_phone_number)
    root_setting.frontlinecloud_api_key = fetch_default_setting(:frontlinecloud_api_key)
    root_setting.save!
  end

  private

  def fetch_default_setting(key)
    return unless configatron.default_settings.key?(key)
    configatron.default_settings[key]
  end
end
