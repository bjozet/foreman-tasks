module Actions
  module Helpers
    module WithContinuousOutput
      # @override
      # array of objects defining fill_continuous_input
      def continuous_output_providers
        []
      end

      def continuous_output
        continuous_output = ::ForemanTasksCore::ContinuousOutput.new
        continuous_output_providers.each do |continous_output_provider|
          continous_output_provider.fill_continuous_output(continuous_output)
        end
        continuous_output
      end

      def fill_planning_errors_to_continuous_output(continuous_output)
        execution_plan.errors.map do |e|
          continuous_output.add_exception(_('Failed to initialize'), e, task.started_at)
        end
      end
    end
  end
end

