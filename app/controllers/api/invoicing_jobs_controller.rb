# frozen_string_literal: true

module Api
  class InvoicingJobsController < Api::ApplicationController
    rescue_from ActionController::ParameterMissing, with: :bad_request
    rescue_from ArgumentError, with: :bad_request

    def index
      project_anchor = current_project_anchor

      render json: find_jobs(project_anchor)
    end

    private

    def find_jobs(project_anchor)
      period = Periods.from_dhis2_period(params.fetch(:period))
      jobs = project_anchor.invoicing_jobs
                           .where(dhis2_period: period.to_quarter.to_dhis2)
      jobs = jobs.where(orgunit_ref: params[:orgunit_refs].split(",")) if params[:orgunit_refs]
      jobs = jobs.where(status: params[:status].split(",")) if params[:status]
      jobs.last(1000)
    end
  end
end
