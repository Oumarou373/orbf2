# == Schema Information
#
# Table name: projects
#
#  id                :integer          not null, primary key
#  name              :string           not null
#  dhis2_url         :string           not null
#  user              :string
#  password          :string
#  bypass_ssl        :boolean          default(FALSE)
#  boolean           :boolean          default(FALSE)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  program_id        :integer          not null
#  status            :string           default("draft"), not null
#  publish_date      :datetime
#  project_anchor_id :integer
#

class Project < ApplicationRecord
  validates :name, presence: true

  validates :dhis2_url, presence: true, url: true
  validates :user, presence: true
  validates :password, presence: true

  has_one :entity_group, dependent: :destroy
  has_many :packages, dependent: :destroy
  has_many :payment_rules, dependent: :destroy
  belongs_to :project_anchor

  def draft?
    status == "draft"
  end

  def publish(date)
    if draft?
      old_project = self
      new_project = nil
      transaction do
        package_association = {
          package_entity_groups: [],
          package_states:        [],
          rules:                 [
            :formulas
          ]
        }
        new_project = deep_clone(
          includes: [
            :entity_group,
            package_association,
            payment_rules: {
              package_payment_rules: [],
              rules:                 [
                :formulas
              ]
            }
          ]
        )
        new_project.save!
        old_project.publish_date = date
        old_project.status = "published"
        raise 'We are here'
        old_project.save!
      end
      new_project
    end
  end

  def missing_rules_kind
    payment_rule ? [] : ["payment"]
  end

  def verify_connection
    return { status: :ko, message: errors.full_messages.join(",") } if invalid?
    infos = dhis2_connection.system_infos.get
    return { status: :ok, message: infos }
  rescue => e
    return { status: :ko, message: e.message }
  end

  def dhis2_connection
    Dhis2::Client.new(
      url:                 dhis2_url,
      user:                user,
      password:            password,
      no_ssl_verification: bypass_ssl
    )
  end

  def unused_packages
    packages.select do |package|
      payment_rules.none? { |payment_rule| payment_rule.packages.include?(package) }
    end
  end

  def export_to_json
    to_json(
      except:  [:created_at, :updated_at, :password, :user],
      include: {
        payment_rules: {
          rule: {
            include: {
              formulas: {}
            }
          }
        },
        packages:      {
          except:  [:created_at, :updated_at],
          include: {
            rules: {
              include: {
                formulas: {}
              }
            }
          }
        }
      }
    )
  end

  def dump_validations
    payment_rules.each do |payment_rule|
      puts "payment_rule #{payment_rule.valid?} #{payment_rule.errors.full_messages}"
      puts "payment_rule #{payment_rule.packages.first}"
      next unless payment_rule.rule.invalid?

      dump_validation_rule(payment_rule.rule)
    end
    packages.each do |package|
      next unless package.invalid?
      puts package.errors.full_messages
      package.rules.each do |rule|
        dump_validation_rule(rule)
      end
    end
  end

  def dump_validation_rule(rule)
    puts "------"
    puts rule.to_json
    puts rule.available_variables_for_values.to_json
    puts rule.errors.full_messages
    rule.formulas.each do |formula|
      next unless formula.invalid?
      puts "------* *** *"
      puts formula.to_json
      puts formula.errors.full_messages
      puts rule.available_variables_for_values
    end
  end

  def dump_rules
    packages.each do |package|
      puts "**** #{package.name} #{package.frequency}"
      package.rules.each do |rule|
        puts "------ Rule #{rule.name} #{rule.kind}"
        rule.formulas.each do |formula|
          puts [formula.code, formula.description, formula.expression].join("\t")
        end
      end
    end
end
end
