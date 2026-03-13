require_relative '../spec_helper'

describe Annotate do
  describe '.version' do
    it 'has version' do
      expect(Annotate.version).to be_instance_of(String)
    end
  end

  describe '.eager_load' do
    let(:options) { { model_dir: ['app/models'], require: [] } }
    let(:rails_application_class) do
      Class.new do
        def eager_load!; end
      end
    end
    let(:rails_application) { instance_spy(rails_application_class) }

    before do
      allow(Annotate).to receive(:require).with('annotate/active_record_patch')
      stub_const('Rails', Module.new)
      stub_const('Rails::Application', Class.new)
      allow(Rails).to receive_messages(application: rails_application, version: '8.1.0')
    end

    it 'uses Rails.application when available' do
      Annotate.eager_load(options)

      expect(rails_application).to have_received(:eager_load!)
    end
  end
end
