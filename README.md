# Unmaintained

[![No Maintenance Intended](http://unmaintained.tech/badge.svg)](http://unmaintained.tech/)

**Unmaintained:** Due to several factors (apparent Things.app instability when using Scripting Bridge, bugs like [#34](https://github.com/cdzombak/thingshub/issues/34) resulting in odd duplicates and project splits, and [the GitHub Authorizations API going away](https://github.com/cdzombak/thingshub/issues/38) which will require rewriting large parts of the software), I’m no longer devoting any time to this project.

---

# ThingsHub

Synchronize issues assigned to you, one-way, from a Github repo into Things.

## Usage

### Configuration

ThingsHub checks for a config file at `~/.thingshubconfig`, then traverses from the home directory down to the current dir (or from the root to the current dir, if the current directory isn't in `~`), merging in `.thingshubconfig` files as it finds them.

This means you can put global configuration and defaults (eg. `githubLogin`, `tagNamespace`) in `~/.thingshubconfig`, leaving project-specific settings (eg. `repoOwner`, `repoName`, `areaName`, `projectPrefix`) in `your-project-dir/.thingshubconfig`, sort of like using git's configuration system.

Configuration parameters may additionally be specified on the command line, like `-githubLogin cdzombak`. Parameters specified on the command line override those found in any configuration files.

See [thingshubconfig.example in this distribution](https://github.com/cdzombak/thingshub/blob/master/thingshubconfig.example) for details on the configuration format.

You may also want to add `.thingshubconfig` to your `~/.gitignore`.

Run with the `-verbose` flag to see the final, resolved configuration.

#### Parameters

These may be used in a configuration file (`param = value`) or on the CLI (`-param value`).

* `githubLogin`: your Github username. Required.
* `tagNamespace`: namespace to use as a prefix for tags imported from Github. Optional; default is "github".
* `delegate`: the sync delegate used to communicate with the local task manager app. Optional; default is Things. Currently only Things is supported.
* `map.label name` (`-"map.label name"` on the CLI, if you need spaces): map a Github label to a local tag name. Optional.
* `repoOwner`: the owner of the Github repo to sync. Required.
* `repoName`: the Github repo to sync. Required.
* `areaName`: the area in Things to use for this project. Optional; default is none.
* `projectPrefix`: prefix which will be applied to project names & tasks’ titles (before the issue number). Optional; default is none.

### Run

The simplest usage is just to run `thingshub` and specify all configuration options on the command line.

Alternatively, run `thingshub` from a project's directory, optionally specifying configuration options via the CLI. ThingsHub will configure itself from your configuration files as described in [the Configuration section](https://github.com/cdzombak/thingshub#configuration).

### Logout/Reset Github OAuth Token

`thingshub -logout <GitHub Username>`

### Version Check

`thingshub -version`

## Installation

**Current version:** v1.1.1.

Installation requires Xcode.

Get the most recent [release](https://github.com/cdzombak/thingshub/releases) and run `make install`. This will install `thingshub` to `/usr/local/bin` and its man page to `/usr/local/share/man/man1`.

### Troubleshooting

Ensure that the target directories exist and you can write to them.

## Workflow

* This never updates GitHub from Things; GitHub is the source of truth.
* This will always create issues in Anytime. You can move them to Today/Upcoming/Someday as desired.
* This *will* move issues to areas/projects to reflect milestone changes. This doesn't change the todo between Today/Anytime/Upcoming/Someday.

### Why one way sync? Why GitHub as the source of truth?

* Issues may be modified by many people online, increasing the chance of conflicts if you modify an issue locally.
	* Conflict management is easy this way, and we probably won't lose much data.
* Issues are often closed as side effects of other operations (merges, commits), so closing issues in your client usually won't make much sense.
* Descriptions on Todos are often used in your task management software for personal notes.
* The entire one-way sync operation is idempotent, so partial sync failures are easily recoverable; just re-trigger the sync.

### Sync (to Things)

* Milestones, if any, are represented as projects in your selected Area, or if no Area, as projects in Anytime/Someday. Projects' due dates reflect the milestone due date.
* Milestones: each project's due date, tags, and status are updated every sync. Name and notes are only touched when creating a new Project.
* A project is not created for an open milestone if you have no issues assigned to you in that milestone.
* Issues without a milestone are placed directly in the selected Area, or if no Area, into Anytime. (If updating an existing task, we won't move it back into Anytime, though.)
* Todos and projects are marked as incomplete/complete based on open/close status in Github. Todos/projects that exist for deleted/unassigned milestones/issues are marked as canceled.
* We only search for existing issues in Today, Anytime, Upcoming, Someday, Projects, and Trash — *not Inbox or Logbook*.
* We don't touch due dates or handle scheduling for tasks.
* Issues: todo's project/area, tags, name, and status are updated every sync. Notes are only touched when the todo is created.
* Pull requests are treated the same as issues, with "(PR #xxx)" instead of just "(#xxx)" in the name.

#### Tags

* When a todo is created/updated, remove any extant "github:" tags, and apply "github:" tags that are currently on the issue.
* When creating/updating a todo/project, add a "via:github" tag.

## Contributors

Thanks to:

* [Chris Dzombak](https://github.com/cdzombak/) • [@cdzombak](https://twitter.com/cdzombak) • [dzombak.com](http://www.dzombak.com)
* [Andrew Sardone](https://github.com/andrewsardone/) • [@andrewa2](https://twitter.com/andrewa2)

## License

[MIT; see LICENSE in this distribution](https://github.com/cdzombak/thingshub/blob/master/LICENSE).

## Dev Notes

- Run `make bootstrap` to set up a local, self-contained environment for CocoaPods. Its only external dependency is Bundler.
- `make pods` runs `bundle exec pod install` for you.

## Implementation details

### Things

#### Identifying synced items:

The following will be placed in the notes field for relevant projects/todos:

* `//thingshub/ORG/REPO/issue/###//`
* `//thingshub/ORG/REPO/milestone/###//`

## Reference Material

### Things and Scripting Bridge

* http://downloads.culturedcode.com/things/download/ThingsAppleScriptGuide.pdf
* https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ScriptingBridgeConcepts/UsingScriptingBridge/UsingScriptingBridge.html

### RAC

* https://github.com/ReactiveCocoa/ReactiveCocoa/blob/8cb404a9be99f9b3515bc16b6874ce85fee37b0b/ReactiveCocoaFramework/ReactiveCocoa/RACStream.h#L98-L125
* http://www.techsfo.com/blog/2013/08/managing-nested-asynchronous-callbacks-in-objective-c-using-reactive-cocoa/
* http://stackoverflow.com/questions/15797081/chaining-dependent-signals-in-reactivecocoa/15827396#15827396
* https://github.com/ReactiveCocoa/ReactiveCocoa/blob/master/ReactiveCocoaFramework/ReactiveCocoa/RACSignal.h#L162-L177
* http://stackoverflow.com/questions/19439636/difference-between-catch-and-subscribeerror
* https://github.com/ReactiveCocoa/GHAPIDemo/blob/befc3f73b9c30fd8679230cdc02d1f5793b705e4/GHAPIDemo/GHDUserViewController.m#L138-L151
* https://github.com/ReactiveCocoa/ReactiveCocoa/blob/fc32fc06d398a99cd7c4c28e102d1ffb4a2e3cf9/Documentation/DesignGuidelines.md#side-effects-occur-for-each-subscription
* https://github.com/cdzombak/thingshub/pull/2
* https://github.com/cdzombak/thingshub/pull/1
* *and more…*

### Github API

* http://developer.github.com/v3/issues/#list-issues-for-a-repository

### KVC, Predicates

* http://nshipster.com/kvc-collection-operators/
* https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/KeyValueCoding/Articles/CollectionOperators.html#//apple_ref/doc/uid/20002176-BAJEAIEE
* https://developer.apple.com/library/mac/documentation/cocoa/conceptual/predicates/Articles/pUsing.html
* http://nshipster.com/nspredicate/

### `NSRunLoop`

* http://hackazach.net/code/2013/08/09/run-run-run-nsrunloop/
* http://cocoafactory.com/blog/2012/09/06/whats-a-run-loop-anyway/
* https://www.mikeash.com/pyblog/friday-qa-2010-01-01-nsrunloop-internals.html
