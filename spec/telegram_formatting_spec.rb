# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'escape_html' do
  it 'экранирует специальные HTML символы' do
    expect(escape_html('<b>"quote" & \'apos\'</b>'))
      .to eq('&lt;b&gt;&quot;quote&quot; &amp; &#39;apos&#39;&lt;/b&gt;')
  end

  it 'корректно обрабатывает nil и пустую строку' do
    expect(escape_html(nil)).to eq('')
    expect(escape_html('')).to eq('')
  end
end

RSpec.describe 'format_telegram_message' do
  it 'формирует сообщение с заголовком и деталями по секциям' do
    message = format_telegram_message(
      'Сборка завершена',
      {
        'Версия' => '1.2.3',
        'Build' => '456',
        'IPA' => 'app.ipa',
        'Ошибка' => 'что-то пошло не так'
      },
      include_pipeline_link: false
    )

    expect(message).to include('<b>Сборка завершена</b>')
    expect(message).to include('📱 v1.2.3')
    expect(message).to include('🔢 b456')
    expect(message).to include('🧭 Контекст')
    expect(message).to include('📦 Артефакты')
    expect(message).to include('❌ Ошибки')
    expect(message).not_to include('Открыть Pipeline')
  end

  it 'добавляет ссылку на pipeline, если она передана' do
    message = format_telegram_message('Заголовок', {}, include_pipeline_link: true, pipeline_url: 'https://example.com/pipeline')

    expect(message).to include('https://example.com/pipeline')
    expect(message).to include('Открыть Pipeline')
  end

  it 'не падает на пустых details' do
    expect { format_telegram_message('Заголовок', nil) }.not_to raise_error
  end
end
