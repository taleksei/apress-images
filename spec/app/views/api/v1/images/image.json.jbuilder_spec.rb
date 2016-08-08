require 'spec_helper'

RSpec.describe "apress/images/api/v1/images/image.json.jbuilder", type: :view do
  let(:schema) do
    {
      type: "object",
      required: ::Swagger::V1::Models::Apress::Images::Image.attributes,
    }.with_indifferent_access
  end

  before do
    render template: "apress/images/api/v1/images/_image",
           formats: :json,
           hander: :jbuilder,
           locals: {image: create(:subject_image)}
  end

  it { expect(rendered).to match_json_schema(schema) }
end
