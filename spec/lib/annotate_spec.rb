require_relative '../spec_helper'

describe Annotate do
  describe '.version' do
    it 'has version' do
      expect(Annotate.version).to be_instance_of(String)
    end
  end

  describe '.eager_load' do
    let(:options) { { model_dir: ['app/models'], require: [] } }

    before do
      allow(Annotate).to receive(:require).with('annotate/active_record_patch')
    end

    it 'uses Rails.application when available' do
      rails_application = instance_double('RailsApplication')
      stub_const('Rails', Module.new)
      stub_const('Rails::Application', Class.new)
      allow(Rails).to receive(:application).and_return(rails_application)
      allow(Rails).to receive(:version).and_return('8.1.0')
      expect(rails_application).to receive(:eager_load!)

      Annotate.eager_load(options)
    end
  end
end
