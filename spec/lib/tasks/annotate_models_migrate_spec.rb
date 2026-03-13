require_relative '../../spec_helper'

describe 'ActiveRecord migration rake task hooks' do
  def load_migrate_tasks(top_level_task, annotation_tasks: ['set_annotation_options'])
    Rake.application = Rake::Application.new

    %w[
      db:migrate
      db:migrate:up
      db:migrate:down
      db:migrate:reset
      db:rollback
      db:migrate:primary
      db:migrate:up:primary
      db:migrate:down:primary
      db:migrate:reset:primary
      db:rollback:primary
    ].each do |task|
      Rake::Task.define_task(task)
    end

    Rake::Task.define_task('db:migrate:redo') do
      Rake::Task['db:rollback'].invoke
      Rake::Task['db:migrate'].invoke
    end

    Rake::Task.define_task('db:migrate:redo:primary') do
      Rake::Task['db:rollback:primary'].invoke
      Rake::Task['db:migrate:primary'].invoke
    end

    @invoked_annotation_tasks = []
    annotation_tasks.each do |task_name|
      Rake::Task.define_task(task_name) do
        @invoked_annotation_tasks << task_name
      end
    end

    Rake.load_rakefile('tasks/annotate_models_migrate.rake')
    Annotate::Migration.class_variable_set(:@@working, false)
    Rake.application.instance_variable_set(:@top_level_tasks, [top_level_task])
  end

  %w[
    db:migrate
    db:migrate:up
    db:migrate:down
    db:migrate:reset
    db:rollback
    db:migrate:primary
    db:migrate:up:primary
    db:migrate:down:primary
    db:migrate:reset:primary
    db:rollback:primary
  ].each do |task_name|
    describe task_name do
      it 'updates annotations without crashing' do
        load_migrate_tasks(task_name)
        allow(Annotate::Migration).to receive(:update_annotations)

        expect { Rake.application.top_level }.not_to raise_error
        expect(Annotate::Migration).to have_received(:update_annotations)
      end
    end
  end

  describe 'db:migrate:redo' do
    it 'updates annotations after each migration task' do
      load_migrate_tasks('db:migrate:redo')
      allow(Annotate::Migration).to receive(:update_annotations)

      expect { Rake.application.top_level }.not_to raise_error
      expect(Annotate::Migration).to have_received(:update_annotations).exactly(3).times
    end
  end

  describe 'db:migrate:redo:primary' do
    it 'updates annotations after each namespaced migration task' do
      load_migrate_tasks('db:migrate:redo:primary')
      allow(Annotate::Migration).to receive(:update_annotations)

      expect { Rake.application.top_level }.not_to raise_error
      expect(Annotate::Migration).to have_received(:update_annotations).exactly(3).times
    end
  end

  it 'prefers app:set_annotation_options when it is defined' do
    load_migrate_tasks('db:migrate', annotation_tasks: %w[set_annotation_options app:set_annotation_options])
    allow(Annotate::Migration).to receive(:update_annotations)

    Rake.application.top_level

    expect(@invoked_annotation_tasks).to eq(['app:set_annotation_options'])
  end

  it 'does not crash when no annotation options task exists' do
    load_migrate_tasks('db:migrate', annotation_tasks: [])
    allow(Annotate::Migration).to receive(:update_annotations)

    expect { Rake.application.top_level }.not_to raise_error
    expect(Annotate::Migration).to have_received(:update_annotations)
  end
end
