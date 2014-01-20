# ThingsHub

Synchronize issues assigned to you, one-way, from a Github repo into Things. (Or, soon, to Omnifocus.)

## Usage

### Installation

* *TBD* to `/usr/local/bin`
* homebrew? via Xcode build target?
* see [#16](https://github.com/cdzombak/thingshub/issues/16)

### Configuration

See [`thingshubconfig.example` in this repo](https://github.com/cdzombak/thingshub/blob/master/thingshubconfig.example) for docs on the config system.

### Running

*TODO*

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

## Future features:

### 1.0

* config: look at `~` specifically first, then search current path; don't require current path to be in `~` • [#14](https://github.com/cdzombak/thingshub/issues/14)
* allow mapping github tag -> local tag (ie. in progress) • [#15](https://github.com/cdzombak/thingshub/issues/15)
* see [Initial Release milestone](https://github.com/cdzombak/thingshub/issues?milestone=1&state=open)

### 1.1

* man page/interactive help
* allow logging out without manually changning keychain
* Use contacts/delegation for issues assigned to others.

## Contributors

Thanks to:

* [Chris Dzombak](https://github.com/cdzombak/) • tw[@cdzombak](https://twitter.com/cdzombak) • adn[@dzombak](https://alpha.app.net/dzombak) • [chris@chrisdzombak.net](mailto:chris@chrisdzombak.net) • [dzombak.com](http://www.dzombak.com)
* [Andrew Sardone](https://github.com/andrewsardone/) • tw[@andrewa2](https://twitter.com/andrewa2) • adn[@andrewsardone](https://alpha.app.net/andrewsardone)

## Dev

Run `scripts/bootstrap` to set up a local, self-contained environment for CocoaPods. Its only external dependency is Bundler.

## Implementation details

### Things

#### Identifying synced items:

The following will be placed in the notes field for relevant projects/todos:

* `//thingshub/ORG/REPO/issue/###//`
* `//thingshub/ORG/REPO/milestone/###//`
