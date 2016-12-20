# == Schema Information
#
# Table name: states
#
#  id           :integer          not null, primary key
#  name         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  configurable :boolean          default(FALSE), not null
#

class State < ApplicationRecord
  validates :name, presence: true

  def self.configurables(conf = "")
    if conf == ""
      where('configurable= ? OR configurable= ?', true, false)
    else
      where configurable: conf
    end
  end
end
