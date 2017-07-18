# == Schema Information
#
# Table name: states
#
#  id           :integer          not null, primary key
#  name         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  configurable :boolean          default(FALSE), not null
#  level        :string           default("activity"), not null
#  project_id   :integer          not null
#

class State < ApplicationRecord
  validates :name, presence: true
  belongs_to :project, inverse_of: :states

  validates :name, uniqueness: { scope: :project_id, message: "should be unique per project" }

  def self.configurables(conf = "")
    if conf == ""
      where("configurable= ? OR configurable= ?", true, false)
    else
      where configurable: conf
    end
  end

  def code
    name.parameterize(separator: "_")
  end

  def package_level?
    level == "package"
  end

  def activity_level?
    level == "activity"
  end

  def to_unified_h
    { name: name }
  end
end
