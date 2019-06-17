require 'rails_helper'

RSpec.describe DependentCreationService do
  include Rails.application.routes.url_helpers
  let(:assessment) { create :assessment }
  let(:service) { described_class.new(request_payload) }

  before { stub_call_to_get_json_schema }

  context 'valid payload without income' do
    let(:request_payload) { valid_payload_without_income }
    describe '#success?' do
      it 'returns true' do
        expect(service.success?).to be true
      end

      it 'creates two dependent records for this assessment' do
        expect {
          service.success?
        }.to change { Dependent.count }.by(2)

        dependent = assessment.dependents.order(:date_of_birth).first
        expect(dependent.date_of_birth).to eq 12.years.ago.to_date
        expect(dependent.in_full_time_education).to be false

        dependent = assessment.dependents.order(:date_of_birth).last
        expect(dependent.date_of_birth).to eq 6.years.ago.to_date
        expect(dependent.in_full_time_education).to be true
      end
    end
  end

  context 'valid payload with income' do
    let(:request_payload) { valid_payload_with_income }
    describe '#success?' do
      it 'creates one dependent' do
        expect {
          service.success?
        }.to change { Dependent.count }.by(1)
      end

      it 'creates three income records' do
        expect {
          service.success?
        }.to change { DependentIncomeReceipt.count }.by(3)

        dirs = assessment.dependents.first.dependent_income_receipts.order(:date_of_payment)
        expect(dirs.first.date_of_payment).to eq 60.days.ago.to_date
        expect(dirs.first.amount).to eq 66.66

        expect(dirs[1].date_of_payment).to eq 40.days.ago.to_date
        expect(dirs[1].amount).to eq 44.44

        expect(dirs.last.date_of_payment).to eq 20.days.ago.to_date
        expect(dirs.last.amount).to eq 22.22
      end
    end
  end

  context 'payload fails JSON schema' do
    let(:request_payload) { invalid_payload }
    describe '#success?' do
      it 'returns false' do
        expect(service.success?).to be false
      end
    end

    describe 'errors' do
      it 'returns array of errors' do
        service.success?
        expect(service.errors.size).to eq 4
        expect(service.errors[0]).to match %r{The property '#/' contains additional properties \[\"extra_property\"\] }
        expect(service.errors[1]).to match %r{The property '#/dependents/0' did not contain a required property of 'in_full_time_education'}
        expect(service.errors[2]).to match %r{The property '#/dependents/0' contains additional properties \[\"extra_dependent_property\"\]}
        expect(service.errors[3]).to match %r{The property '#/dependents/1/income/0' contains additional properties \[\"reason\"\]}
      end
    end

    it 'does not create a Dependent record' do
      expect {
        service.success?
      }.not_to change { Dependent.count }
    end

    it 'does not create any DependentIncomeReceipt records' do
      expect {
        service.success?
      }.not_to change { DependentIncomeReceipt.count }
    end
  end

  context 'payload fails ActiveRecord validations' do
    let(:request_payload) { payload_with_future_dates }
    describe '#success?' do
      it 'returns false' do
        expect(service.success?).to be false
      end

      it 'does not create a Dependent record' do
        expect {
          service.success?
        }.not_to change { Dependent.count }
      end

      it 'does not create any DependentIncomeReceipt records' do
        expect {
          service.success?
        }.not_to change { DependentIncomeReceipt.count }
      end
    end

    describe 'errors' do
      it 'returns an error payload' do
        service.success?
        expect(service.errors.size).to eq 3
        expect(service.errors[0]).to eq 'Dependent income receipts is invalid'
        expect(service.errors[1]).to eq 'Date of birth cannot be in future'
        expect(service.errors[2]).to eq 'Date of payment cannot be in the future'
      end
    end
  end

  def invalid_payload
    {
      assessment_id: assessment.id,
      extra_property: 'this should not be here',
      dependents: [
        {
          extra_dependent_property: 'this should not be here',
          date_of_birth: 'not-a-valid-date'
        },
        {
          date_of_birth: '2016-02-03',
          in_full_time_education: true,
          income: [
            date_of_payment: 2.days.ago,
            amount: 44.00,
            reason: 'extra property'
          ]
        }
      ]
    }.to_json
  end

  def valid_payload_without_income
    {
      assessment_id: assessment.id,
      dependents: [
        {
          date_of_birth: 12.years.ago.to_date,
          in_full_time_education: false
        },
        {
          date_of_birth: 6.years.ago.to_date,
          in_full_time_education: true
        }
      ]
    }.to_json
  end

  def valid_payload_with_income
    {
      assessment_id: assessment.id,
      dependents: [
        {
          date_of_birth: 12.years.ago.to_date,
          in_full_time_education: false,
          income: [
            {
              date_of_payment: 60.days.ago.to_date,
              amount: 66.66
            },
            {
              date_of_payment: 40.days.ago.to_date,
              amount: 44.44
            },
            {
              date_of_payment: 20.days.ago.to_date,
              amount: 22.22
            }
          ]
        }

      ]
    }.to_json
  end

  def payload_with_future_dates
    {
      assessment_id: assessment.id,
      dependents: [
        {
          date_of_birth: 3.years.from_now,
          in_full_time_education: false,
          income: [
            {
              date_of_payment: Date.tomorrow,
              amount: 66.66
            },
            {
              date_of_payment: 40.days.ago.to_date,
              amount: 44.44
            },
            {
              date_of_payment: 20.days.ago.to_date,
              amount: 22.22
            }
          ]
        }

      ]
    }.to_json
  end

  def expected_result_payload
    {
      status: :ok,
      assessment_id: assessment.id,
      links: [
        {
          href: assessment_properties_path(assessment),
          rel: 'capital',
          type: 'POST'
        }
      ]
    }.to_json
  end
end
