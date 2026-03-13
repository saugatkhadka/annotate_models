require_relative '../../spec_helper'

describe Annotate do
  describe '.load_tasks' do
    before do
      Rake.application = Rake::Application.new
      Rake::Task.define_task(:environment)
      described_class.instance_variable_set('@tasks_loaded', false)
    end

    after do
      described_class.instance_variable_set('@tasks_loaded', false)
    end

    it 'loads the annotate rake tasks' do
      described_class.load_tasks

      expect(Rake::Task.task_defined?('annotate_models')).to be(true)
      expect(Rake::Task.task_defined?('annotate_routes')).to be(true)
      expect(Rake::Task.task_defined?('remove_annotation')).to be(true)
    end

    it 'does not duplicate tasks when called twice' do
      described_class.load_tasks
      loaded_task_count = Rake::Task.tasks.size

      described_class.load_tasks

      expect(Rake::Task.tasks.size).to eq(loaded_task_count)
    end
  end
end
