# Rails 8 / Ruby 3.4 upgrade notes

I created this fork to keep `annotate` usable on current Ruby and Rails versions without changing the public surface area more than necessary. The goal was to keep the gem name, CLI behavior, and rake integration familiar, while removing the version caps and brittle internals that prevented the gem from working on Ruby 3.4 and Rails / ActiveRecord 8.1.

## What I found first

The initial blockers were mostly compatibility ceilings and assumptions that had gone stale:

- the gemspec still prevented installing with ActiveRecord 8.x
- the local development Gemfile could not bundle modern Rails versions
- CI only covered Ruby 2.7
- route annotation still depended on `rake routes`
- Rails eager loading used private subclass discovery
- migration version lookup and migrate hooks relied on older ActiveRecord behavior

None of those issues required a large redesign. The core annotation logic was still in good shape, so the upgrade work was mainly about modernizing integration points.

## What I changed

### 1. Dependency and CI updates

I widened the dependency bounds so the gem can install with ActiveRecord 8.1 while keeping the gem name as `annotate`.

I also updated the development setup so I could actually exercise the supported combinations:

- Ruby 3.2
- Ruby 3.3
- Ruby 3.4
- Rails 7.2
- Rails 8.1

To do that cleanly, I added dedicated gemfiles for Rails 7.2 and 8.1 and updated GitHub Actions to run the compatibility matrix instead of the old single-version setup.

### 2. Route annotation compatibility

Historically, route annotation depended on `rake routes`. That worked for older apps, but it is not the most reliable entrypoint for modern Rails projects.

I changed route annotation to prefer:

1. `bin/rails routes`
2. `bundle exec rails routes`
3. `rake routes`

This keeps older projects working while making Rails 7.2 and 8.1 behave more naturally. The actual annotation output format was left alone.

### 3. Rails eager loading and boot behavior

The previous code path used private Rails subclass lookup to find the application class before eager loading models. That was fragile on newer Rails versions.

I changed it to use `Rails.application.eager_load!` when available, and only fall back to the older approach if needed. That keeps boot behavior close to the original intent while avoiding private internals on newer Rails.

### 4. Migration version lookup

The model annotation code still used `ActiveRecord::Migrator.current_version`, which is not the safest interface for current Rails releases.

I updated that logic to prefer the migration context exposed by the connection pool and only fall back to the old migrator API when necessary. This keeps `--show-migration` working across the newer Rails versions.

### 5. db:migrate hook safety

The original migrate hook logic assumed a narrower set of task names and depended on top-level task enhancement patterns that were more brittle than necessary.

I updated the hook loading so it:

- works with the main migration tasks
- works with namespaced multi-database task variants
- does not crash when the annotation options task is missing
- still prefers `app:set_annotation_options` when that task exists

The goal here was not to redesign the feature, only to make the existing auto-annotate-on-migrate behavior survive newer Rails task layouts.

## Tests I added or updated

I added and updated tests to cover the compatibility goals directly:

- model annotation still works
- route annotation still works
- rake tasks still load
- db:migrate hooks do not crash
- route command fallback order is exercised
- schema version lookup works on modern ActiveRecord APIs

I also verified the suite against Rails 7.2 and Rails 8.1 gemfiles locally where possible.

## Behavior I intentionally kept the same

I tried to avoid behavior churn.

- The gem is still named `annotate`.
- The CLI flags are still the same.
- The rake task names are still the same.
- Route annotation still produces the same style of header comments.
- The migrate hook still updates models and routes using the existing task flow.

The most visible intentional compatibility change is only the command used to fetch routes on newer Rails applications.

## Ruby 3.4 notes

I did not find `Fixnum` / `Bignum` usage in the project itself, so there was no large constant-renaming pass to do inside the gem code. The main Ruby 3.4 work here was instead:

- removing old dependency assumptions
- verifying the test suite under Ruby 3.4
- accounting for updated backtrace formatting in tests
- handling older helper gems during test execution where Ruby removed APIs such as `File.exists?`

## Why this fork stays intentionally small

This fork exists to keep the original project usable on newer stacks, not to redefine how annotate works.

That is why the changes focus on:

- installation compatibility
- Rails integration compatibility
- test coverage
- documentation

and not on changing the annotation format or user-facing workflow.

## Current outcome

After these updates, this fork supports:

- Ruby 3.2.x, 3.3.x, 3.4.x
- Rails 7.2.x and 8.1.x
- ActiveRecord 7.2.x and 8.1.x

while keeping the gem name as `annotate` and preserving the original CLI and rake behavior as closely as possible.
