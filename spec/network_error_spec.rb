# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'network_error?' do
  it 'возвращает true для сетевых ошибок' do
    ['timeout', 'connection', 'network', 'socket',
     'temporarily unavailable', 'service unavailable',
     'bad gateway', 'gateway timeout', 'internal server error', 'rate limit'].each do |msg|
      expect(network_error?(StandardError.new("Some #{msg} occurred"))).to be(true), "ожидался true для #{msg}"
    end
  end

  it 'возвращает false для несетевых ошибок' do
    expect(network_error?(StandardError.new('invalid credentials'))).to be false
  end
end
