# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'retry_with_backoff' do
  before do
    allow_any_instance_of(Object).to receive(:sleep)
  end

  it 'возвращает результат при успехе с первой попытки' do
    calls = 0
    result = retry_with_backoff(max_retries: 3, delay: 0.01) do
      calls += 1
      'ok'
    end

    expect(result).to eq('ok')
    expect(calls).to eq(1)
  end

  it 'успешно завершается после N неудачных попыток' do
    calls = 0
    result = retry_with_backoff(max_retries: 5, delay: 0.01) do
      calls += 1
      raise 'connection timeout' if calls < 3

      'success'
    end

    expect(result).to eq('success')
    expect(calls).to eq(3)
  end

  NON_RETRYABLE_TESTFLIGHT_ERRORS.each do |error_substring|
    it "считает успехом ошибку «#{error_substring}» без повторов" do
      calls = 0
      result = retry_with_backoff(max_retries: 3, delay: 0.01) do
        calls += 1
        raise "Some error: #{error_substring}"
      end

      expect(result).to be true
      expect(calls).to eq(1)
    end
  end

  it 'выбрасывает исключение после исчерпания всех попыток' do
    calls = 0
    expect do
      retry_with_backoff(max_retries: 3, delay: 0.01) do
        calls += 1
        raise 'boom'
      end
    end.to raise_error('boom')

    expect(calls).to eq(3)
  end

  it 'использует экспоненциальную задержку между попытками' do
    sleep_calls = []
    allow_any_instance_of(Object).to receive(:sleep) { |_, seconds| sleep_calls << seconds }

    calls = 0
    retry_with_backoff(max_retries: 4, delay: 2.0) do
      calls += 1
      raise 'network timeout' if calls < 4

      'done'
    end

    expect(sleep_calls).to eq([2.0, 4.0, 8.0])
  end
end
