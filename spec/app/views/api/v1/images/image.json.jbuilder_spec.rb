require 'spec_helper'

RSpec.describe "apress/images/api/v1/images/image.json.jbuilder", type: :view do
  let(:schema) do
    {
      type: "object",
      required: ::Swagger::V1::Models::Apress::Images::Image.attributes
    }.with_indifferent_access
  end

  let(:styles_schema) do
    {
      type: 'array',
      items: {
        type: 'object'
      }
    }.with_indifferent_access
  end

  before do
    render template: "apress/images/api/v1/images/_image",
           formats: :json,
           hander: :jbuilder,
           locals: {image: create(:subject_image)}
  end

  it do
    expect(rendered).to match_json_schema(schema)
    expect(JSON.parse(rendered)['styles'].to_json).to match_json_schema(styles_schema)
  end

  it 'return full image url' do
    expect(JSON.parse(rendered)['img']).to include 'http://test/system/images'
  end
end
