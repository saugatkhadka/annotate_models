require_relative '../../../spec_helper'

describe AnnotateRoutes::HeaderGenerator do
  describe '.generate' do
    let(:status) { instance_double(Process::Status, success?: true) }
    let(:routes_output) do
      <<~OUTPUT
        Prefix Verb URI Pattern Controller#Action
        root GET / root#index
      OUTPUT
    end

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('bin/rails').and_return(bin_rails_exists)
      allow(File).to receive(:exist?).with('Gemfile').and_return(gemfile_exists)
    end

    context 'when bin/rails is available' do
      let(:bin_rails_exists) { true }
      let(:gemfile_exists) { true }

      it 'prefers bin/rails routes' do
        expect(Open3).to receive(:capture2e).with('bin/rails', 'routes').and_return([routes_output, status])

        described_class.generate
      end
    end

    context 'when bin/rails is unavailable but Gemfile exists' do
      let(:bin_rails_exists) { false }
      let(:gemfile_exists) { true }

      it 'falls back to bundle exec rails routes' do
        expect(Open3).to receive(:capture2e).with('bundle', 'exec', 'rails', 'routes').and_return([routes_output, status])

        described_class.generate
      end
    end

    context 'when modern route commands are unavailable' do
      let(:bin_rails_exists) { false }
      let(:gemfile_exists) { false }

      it 'falls back to rake routes' do
        expect(Open3).to receive(:capture2e).with('rake', 'routes').and_return([routes_output, status])

        described_class.generate
      end
    end

    context 'when bin/rails fails' do
      let(:bin_rails_exists) { true }
      let(:gemfile_exists) { true }
      let(:failed_status) { instance_double(Process::Status, success?: false) }

      it 'tries bundle exec rails before rake routes' do
        expect(Open3).to receive(:capture2e).with('bin/rails', 'routes').and_return(['', failed_status])
        expect(Open3).to receive(:capture2e).with('bundle', 'exec', 'rails', 'routes').and_return([routes_output, status])

        described_class.generate
      end
    end
  end
end
