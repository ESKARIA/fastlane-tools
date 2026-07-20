# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'multiplatform_scheme?' do
  around do |example|
    original = ENV['MULTIPLATFORM_SCHEME']
    example.run
  ensure
    if original.nil?
      ENV.delete('MULTIPLATFORM_SCHEME')
    else
      ENV['MULTIPLATFORM_SCHEME'] = original
    end
  end

  it 'false по умолчанию — без options[:multiplatform] и без ENV' do
    ENV.delete('MULTIPLATFORM_SCHEME')
    expect(multiplatform_scheme?({})).to be(false)
  end

  it 'true при options[:multiplatform] == true' do
    ENV.delete('MULTIPLATFORM_SCHEME')
    expect(multiplatform_scheme?(multiplatform: true)).to be(true)
  end

  it 'false при options[:multiplatform] == "true" (строка, не булево) без ENV' do
    ENV.delete('MULTIPLATFORM_SCHEME')
    expect(multiplatform_scheme?(multiplatform: 'true')).to be(false)
  end

  it 'true при ENV["MULTIPLATFORM_SCHEME"] == "true"' do
    ENV['MULTIPLATFORM_SCHEME'] = 'true'
    expect(multiplatform_scheme?({})).to be(true)
  end

  it 'false при ENV["MULTIPLATFORM_SCHEME"] с другим значением' do
    ENV['MULTIPLATFORM_SCHEME'] = 'false'
    expect(multiplatform_scheme?({})).to be(false)
  end

  it 'false при пустом ENV["MULTIPLATFORM_SCHEME"]' do
    ENV['MULTIPLATFORM_SCHEME'] = ''
    expect(multiplatform_scheme?({})).to be(false)
  end
end
