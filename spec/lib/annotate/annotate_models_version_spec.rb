require_relative '../../spec_helper'
require 'active_record'

describe AnnotateModels do
  describe '.current_schema_version' do
    let(:migration_context_class) do
      Class.new do
        def current_version; end
      end
    end
    let(:connection_pool_class) do
      Class.new do
        def migration_context; end
      end
    end
    let(:connection_class) do
      Class.new do
        def migration_context; end
      end
    end
    let(:migration_context) { instance_double(migration_context_class, current_version: 20_260_313_010_101) }
    let(:connection_pool) { instance_double(connection_pool_class, migration_context: migration_context) }
    let(:connection) { instance_double(connection_class, respond_to?: false) }

    it 'uses the connection pool migration context when available' do
      allow(ActiveRecord::Base).to receive(:connection_pool).and_return(connection_pool)

      expect(described_class.current_schema_version).to eq(20_260_313_010_101)
    end

    it 'falls back to ActiveRecord::Migrator.current_version' do
      allow(connection_pool).to receive(:respond_to?).with(:migration_context).and_return(false)
      allow(ActiveRecord::Base).to receive_messages(connection_pool: connection_pool, connection: connection)
      stub_const('ActiveRecord::Migrator', Class.new)
      allow(ActiveRecord::Migrator).to receive(:current_version).and_return(123)

      expect(described_class.current_schema_version).to eq(123)
    end
  end
end
