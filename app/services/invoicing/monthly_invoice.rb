module Invoicing
  class MonthlyInvoice < Struct.new(:date, :entity, :project, :activity_results, :package_results, :payment_result)


    def puts(message = "")
      @lines ||= []
      @lines << message
    end

    def lines
      @lines
    end

    def dump_invoice
      puts "-------********* #{entity.name} #{date}************------------"
      if activity_results
        activity_results.flatten.group_by(&:package).map do |package, results|
          puts "************ Package #{package.name} "
          puts package.invoice_details.join("\t")
          results.each do |result|
            line = package.invoice_details.map { |item| d_to_s(item, result.solution[item]) }
            puts line.join("\t\t")
          end
          next unless package_results
          package_line = package.package_rule.formulas.map(&:code).map do |item|
            package_result = package_results.find { |pr| pr.package == package }
            next unless package_result.solution[item]
            [item, d_to_s(item, package_result.solution[item])].join("=")
          end
          puts "#{package_line.compact.join("\n")}"
        end
      end

      if payment_result
        package_line = project.payment_rules.first.rule.formulas.map do |formula|
          [formula.code, d_to_s(formula.code, payment_result.solution[formula.code])].join(" : ")
        end
        puts "************ payments "
        puts package_line.join("\n")
      end
      puts
    end

    def d_to_s(item, decimal)
      return "%.2f" % decimal if decimal.is_a? Numeric
      decimal
    end

    def to_json(options)
      to_h.to_json(options)
    end
  end
end
