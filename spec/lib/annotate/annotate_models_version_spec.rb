require_relative '../../spec_helper'
require 'active_record'

describe AnnotateModels do
  describe '.current_schema_version' do
    it 'uses the connection pool migration context when available' do
      migration_context = instance_double('MigrationContext', current_version: 20_260_313_010_101)
      connection_pool = instance_double('ConnectionPool', migration_context: migration_context)

      allow(ActiveRecord::Base).to receive(:connection_pool).and_return(connection_pool)

      expect(described_class.current_schema_version).to eq(20_260_313_010_101)
    end

    it 'falls back to ActiveRecord::Migrator.current_version' do
      connection_pool = instance_double('ConnectionPool')
      connection = instance_double('Connection')

      allow(connection_pool).to receive(:respond_to?).with(:migration_context).and_return(false)
      allow(ActiveRecord::Base).to receive(:connection_pool).and_return(connection_pool)
      allow(ActiveRecord::Base).to receive(:connection).and_return(connection)
      allow(connection).to receive(:respond_to?).with(:migration_context).and_return(false)
      stub_const('ActiveRecord::Migrator', Class.new)
      allow(ActiveRecord::Migrator).to receive(:current_version).and_return(123)

      expect(described_class.current_schema_version).to eq(123)
    end
  end
end
