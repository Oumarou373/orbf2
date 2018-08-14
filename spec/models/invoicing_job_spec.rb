# frozen_string_literal: true

# == Schema Information
#
# Table name: invoicing_jobs
#
#  id                :integer          not null, primary key
#  project_anchor_id :integer          not null
#  orgunit_ref       :string           not null
#  dhis2_period      :string           not null
#  user_ref          :string
#  processed_at      :datetime
#  errored_at        :datetime
#  last_error        :string
#  duration_ms       :integer
#  status            :string
#  sidekiq_job_ref   :string
#


require "rails_helper"

RSpec.describe InvoicingJob, type: :model do
  let(:program) { create :program }
  let(:project_anchor) { create :project_anchor, program: program }


  it "handle nicely when no invoicing job" do
    InvoicingJob.execute(project_anchor, "2016Q4", "orgunit_ref") do
      sleep 0.5
    end
    expect(InvoicingJob.all.size).to eq(0)
  end

  describe "when invoicing job exist" do
    let!(:invoicing_job) { project_anchor.invoicing_jobs.create!(dhis2_period: "2016Q4", orgunit_ref: "orgunit_ref") }

    it "track duration on success and resets error infos" do
      slept = false
      InvoicingJob.execute(project_anchor, "2016Q4", "orgunit_ref") do
        sleep 0.5
        slept = true
      end
      invoicing_job.reload
      expect(slept).to eq true
      expect(invoicing_job.status).to eq("processed")
      expect(invoicing_job.duration_ms).to be >= 400

      expect(invoicing_job.processed_at).not_to be_nil
      expect(invoicing_job.errored_at).to be_nil
      expect(invoicing_job.last_error).to be_nil
    end

    it "track duration on error and resets processed info" do
      invoicing_job
      slept = false
      expect {
        InvoicingJob.execute(project_anchor, "2016Q4", "orgunit_ref") do
          sleep 0.5
          slept = true
          raise "Failed miserably"
        end
      }.to raise_error("Failed miserably")
      invoicing_job.reload

      expect(invoicing_job.status).to eq("errored")
      expect(invoicing_job.processed_at).to be_nil
      expect(invoicing_job.errored_at).not_to be_nil
      expect(invoicing_job.last_error).to eq("RuntimeError: Failed miserably")
      expect(invoicing_job.duration_ms).to be >= 400
    end
  end
end
