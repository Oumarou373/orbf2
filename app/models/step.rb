class Step
  include ActiveModel::Model
  attr_accessor(:name, :status, :hint, :kind, :highlighted)
end