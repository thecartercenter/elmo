# frozen_string_literal: true

class Mission < ApplicationRecord
  def generate_shortcode
    charset = ("a".."z").to_a + ("0".."9").to_a
    begin
      self.shortcode = 2.times.map { charset.sample }.join
    end while Mission.exists?(shortcode: shortcode)
  end
end

class GenerateShortcodesForMissions < ActiveRecord::Migration[4.2]
  def up
    Mission.find_each do |mission|
      mission.generate_shortcode
      mission.save!
    end
  end

  def down
    Mission.update_all(shortcode: nil)
  end
end
