# ThingsHub

Synchronize issues assigned to you, one-way, from a Github repo into Things. (Or, soon, to Omnifocus.)

## Usage

### Configuration

See [`thingshubconfig.example` in this repo](https://github.com/cdzombak/thingshub/blob/master/thingshubconfig.example) for docs on the config system.

### Run

*TODO*

### Logout/Reset Github OAuth Token

`security delete-generic-password -s "ThingsHub-Github"`

## Installation

Run `scripts/install`. This will install `thingshub` to `/usr/local/bin` and its man page to `/usr/local/share/man/man1`.

### Manual alternative

Run `xcodebuild -workspace thingshub.xcworkspace -scheme thingshub -configuration Release install`.

### Troubleshooting

Ensure that the target directories exist and you can write to them.

## Workflow

* This never updates Github from Things; GH is the canonical source of truth.
* This will always create issues in Next, except for issues that have no area *or* project. You can move to Today/Someday as desired.
* This *will* move issues to areas/projects to reflect milestone changes. This doesn't touch Today/Next/Someday.

### Why one way sync? Why Github as the source of truth?

* Issues may be modified by many people online, increasing the chance of conflicts if you modify an issue locally.
	* Conflict management is easy this way, and we probably won't lose much data.
* Issues are typically closed as side effects of other operations (merges, commits), so closing issues in your client usually won't make much sense.
* Descriptions on Todos are often used in your task management software for personal notes.
* The entire one-way sync operation is idempotent, so partial sync failures are easily recoverable; just re-trigger the sync.

### Sync (to Things)

* Milestones, if any, are represented as projects in your selected Area, or if no Area, as projects in Next. Projects' due dates reflect the milestone due date.
* Issues without a milestone are placed directly in the selected Area, or if no Area, into Next. (If updating an existing task, we won't move it back into Next, though.)
* Todos and projects are marked as incomplete/complete based on open/close status in Github. Todos/projects that exist for deleted/unassigned milestones/issues are marked as canceled.
* We only search for existing issues in Today, Next, Scheduled, Someday, Projects, and Trash — *not Inbox or Logbook*.
* We don't touch due dates or handle scheduling for tasks.
* Milestones: project's name, notes, due date, tags, status are updated every sync.
* Issues: todo's project/area, tags, name, and status are updated every sync. Notes are only touched when the todo is created.
* Pull requests are treated the same as issues, with "(PR #xxx)" instead of just "(#xxx)" in the name.

#### Tags

* When a todo is created/updated, remove any extant "github:" tags, and apply "github:" tags that are currently on the issue.
* When creating/updating a todo/project, add a "via:github" tag.

## Contributors

Thanks to:

* [Chris Dzombak](https://github.com/cdzombak/) • tw[@cdzombak](https://twitter.com/cdzombak) • adn[@dzombak](https://alpha.app.net/dzombak) • [chris@chrisdzombak.net](mailto:chris@chrisdzombak.net) • [dzombak.com](http://www.dzombak.com)
* [Andrew Sardone](https://github.com/andrewsardone/) • tw[@andrewa2](https://twitter.com/andrewa2) • adn[@andrewsardone](https://alpha.app.net/andrewsardone)

## Roadmap

### 1.1

* Allow logging out without manually modifying keychain
* Use contacts/delegation for issues assigned to others

## Dev Notes

Run `scripts/bootstrap` to set up a local, self-contained environment for CocoaPods. Its only external dependency is Bundler.

----

## Implementation details

### Things

#### Identifying synced items:

The following will be placed in the notes field for relevant projects/todos:

* `//thingshub/ORG/REPO/issue/###//`
* `//thingshub/ORG/REPO/milestone/###//`

### Reference Material

#### Things and Scripting Bridge

* http://downloads.culturedcode.com/things/download/ThingsAppleScriptGuide.pdf
* https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ScriptingBridgeConcepts/UsingScriptingBridge/UsingScriptingBridge.html#//apple_ref/doc/uid/TP40006104-CH4-DontLinkElementID_12

#### RAC

* https://github.com/ReactiveCocoa/ReactiveCocoa/blob/8cb404a9be99f9b3515bc16b6874ce85fee37b0b/ReactiveCocoaFramework/ReactiveCocoa/RACStream.h#L98-L125
* http://www.techsfo.com/blog/2013/08/managing-nested-asynchronous-callbacks-in-objective-c-using-reactive-cocoa/
* http://stackoverflow.com/questions/15797081/chaining-dependent-signals-in-reactivecocoa/15827396#15827396
* https://github.com/ReactiveCocoa/ReactiveCocoa/blob/master/ReactiveCocoaFramework/ReactiveCocoa/RACSignal.h#L162-L177
* http://stackoverflow.com/questions/19439636/difference-between-catch-and-subscribeerror
* https://github.com/ReactiveCocoa/GHAPIDemo/blob/befc3f73b9c30fd8679230cdc02d1f5793b705e4/GHAPIDemo/GHDUserViewController.m#L138-L151
* https://github.com/ReactiveCocoa/ReactiveCocoa/blob/fc32fc06d398a99cd7c4c28e102d1ffb4a2e3cf9/Documentation/DesignGuidelines.md#side-effects-occur-for-each-subscription
* https://github.com/cdzombak/thingshub/pull/2
* https://github.com/cdzombak/thingshub/pull/1

*and more…*

#### Github API

* http://developer.github.com/v3/issues/#list-issues-for-a-repository

#### KVC, Predicates

* http://nshipster.com/kvc-collection-operators/
* https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/KeyValueCoding/Articles/CollectionOperators.html#//apple_ref/doc/uid/20002176-BAJEAIEE
* https://developer.apple.com/library/mac/documentation/cocoa/conceptual/predicates/Articles/pUsing.html
* http://nshipster.com/nspredicate/

#### `NSRunLoop`

* http://hackazach.net/code/2013/08/09/run-run-run-nsrunloop/
* http://cocoafactory.com/blog/2012/09/06/whats-a-run-loop-anyway/
* https://www.mikeash.com/pyblog/friday-qa-2010-01-01-nsrunloop-internals.html
