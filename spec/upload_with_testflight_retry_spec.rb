# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'upload_with_testflight_retry' do
  before do
    allow_any_instance_of(Object).to receive(:sleep)
  end

  it 'возвращает true при обычном успехе' do
    allow(self).to receive(:testflight).and_return(true)

    expect(upload_with_testflight_retry({ some: 'param' })).to be true
    expect(self).to have_received(:testflight).with(some: 'param').once
  end

  it 'возвращает true, если testflight сообщает "already distributed" после retry' do
    calls = 0
    allow(self).to receive(:testflight) do
      calls += 1
      raise 'Build already exists in this group' if calls == 1

      true
    end

    result = upload_with_testflight_retry({}, max_retries: 3, delay: 0.01)

    expect(result).to be true
  end

  it 'пробрасывает исключение при настоящей ошибке' do
    allow(self).to receive(:testflight).and_raise('some real upload failure')

    expect do
      upload_with_testflight_retry({}, max_retries: 1, delay: 0.01)
    end.to raise_error('some real upload failure')
  end
end
