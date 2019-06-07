module WorkflowService
  class DisposableCapitalAssessment < BaseWorkflowService
    def call # rubocop:disable Metrics/AbcSize
      capital = response_capital
      capital.liquid_capital_assessment = calculate_liquid_capital
      capital.property = calculate_property
      capital.vehicles = calculate_vehicles
      capital.non_liquid_capital_assessment = calculate_non_liquid_capital
      capital.single_capital_assessment = sum_assessed_values(capital)
      capital.pensioner_disregard = PensionerCapitalDisregard.new(@particulars).value
      capital.disposable_capital_assessment = capital.single_capital_assessment - capital.pensioner_disregard
      capital.total_capital_lower_threshold = Threshold.value_for(:capital_lower, at: @submission_date)
      capital.total_capital_upper_threshold = Threshold.value_for(:capital_upper, at: @submission_date)
      true
    end

    private

    def calculate_liquid_capital
      LiquidCapitalAssessment.new(applicant_capital.liquid_capital).call
    end

    def calculate_non_liquid_capital
      NonLiquidCapitalAssessment.new(applicant_capital.non_liquid_capital).call
    end

    def calculate_property
      PropertyAssessment.new(applicant_capital.property, @submission_date).call
    end

    def calculate_vehicles
      VehicleAssessment.new(applicant_capital.vehicles, @submission_date).call
    end

    def sum_assessed_values(capital)
      (capital.liquid_capital_assessment +
        capital.property.main_home.assessed_capital_value +
        capital.property.additional_properties.sum(&:assessed_capital_value) +
        capital.vehicles.sum(&:assessed_value) +
        capital.non_liquid_capital_assessment).round(2)
    end
  end
end
