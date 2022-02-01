require "rails_helper"

RSpec.describe EmploymentsController, type: :request do
  describe "POST employment_income" do
    let!(:assessment) { create :assessment }
    let(:assessment_id) { assessment.id }
    let(:gross_income_summary) { assessment.gross_income_summary }
    let(:params) { employment_income_params }
    let(:headers) { { "CONTENT_TYPE" => "application/json" } }

    subject { post assessment_employments_path(assessment_id), params: params.to_json, headers: headers }

    context "valid payload" do
      context "with two employments" do
        it "returns http success", :show_in_doc do
          subject
          expect(response).to have_http_status(:success)
        end

        it "creates two employment income records with associated EmploymentPayment records" do
          subject
          expect(Employment.count).to eq 2
          expect(EmploymentPayment.count).to eq 6
        end

        it "generates a valid response" do
          subject
          expect(parsed_response[:success]).to eq true
          expect(parsed_response[:errors]).to be_empty
        end
      end
    end

    context "invalid_payload" do
      context "missing data in the second employment" do
        let(:params) do
          new_hash = employment_income_params
          new_hash[:employment_income].last.delete(:name)
          new_hash
        end

        it "returns unsuccessful", :show_in_doc do
          subject
          expect(response.status).to eq 422
        end

        it "contains success false in the response body" do
          subject
          expect(parsed_response).to eq(errors: ["Missing parameter name"], success: false)
        end

        it "does not create any employment records" do
          expect { subject }.not_to change(Employment, :count)
        end

        it "does not create employment payment records" do
          expect { subject }.not_to change(EmploymentPayment, :count)
        end
      end
    end

    context "invalid_assessment_id" do
      let(:assessment_id) { SecureRandom.uuid }

      it "returns unsuccessful" do
        subject
        expect(response.status).to eq 422
      end

      it "contains success false in the response body" do
        subject
        expect(parsed_response).to eq(errors: ["No such assessment id"], success: false)
      end
    end

    def employment_income_params
      {
        employment_income: [
          {
            name: "Job 1",
            payments: [
              {
                date: "2021-10-30",
                gross: 1046.00,
                benefits_in_kind: 16.60,
                tax: -104.10,
                national_insurance: -18.66,
                net_employment_income: 898.84,
              },
              {
                date: "2021-10-30",
                gross: 1046.00,
                benefits_in_kind: 16.60,
                tax: -104.10,
                national_insurance: -18.66,
                net_employment_income: 898.84,
              },
              {
                date: "2021-10-30",
                gross: 1046.00,
                benefits_in_kind: 16.60,
                tax: -104.10,
                national_insurance: -18.66,
                net_employment_income: 898.84,
              }
            ],
          },
          {
            name: "Job 2",
            payments: [
              {
                date: "2021-10-30",
                gross: 1046.00,
                benefits_in_kind: 16.60,
                tax: -104.10,
                national_insurance: -18.66,
                net_employment_income: 898.84,
              },
              {
                date: "2021-10-30",
                gross: 1046.00,
                benefits_in_kind: 16.60,
                tax: -104.10,
                national_insurance: -18.66,
                net_employment_income: 898.84,
              },
              {
                date: "2021-10-30",
                gross: 1046.00,
                benefits_in_kind: 16.60,
                tax: -104.10,
                national_insurance: -18.66,
                net_employment_income: 898.84,
              }
            ],
          }
        ],
      }
    end
  end
end