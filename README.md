# ThingsHub

Synchronize issues assigned to you, one-way, from a Github repo into Things. (Or, soon, to Omnifocus.)

*A more complete README, featuring complete sentences, is forthcoming.*

## Dev

Run `scripts/bootstrap` to set up a local, self-contained environment for CocoaPods. Its only external dependency is Bundler.

## Usage

### Installation

*TBD* to `/usr/local/bin`, hopefully via Homebrew

### Configuration

See `thingshubconfig.example` in this repo for docs on the config system.

### Workflow notes

* This never updates Github from Things; GH is the canonical source of truth.
* This will always create issues in Next, except for issues that have no area *or* project. You can move to Today/Someday as desired.
* This *will* move issues to areas/projects to reflect milestone changes. This doesn't touch Today/Next/Someday.

#### Why GitHub as the source of truth?

* Issues may be modified by many people, vastly increasing the chance of conflicts
* Conflict management is easy this way, and we probably won't lose much data
* Issues are usually closed as side effects of other operations (merges, commits) anyway
* Descriptions are often used in Things for personal notes
* You don't want your local tags DB to reflect 1:1 Github - too noisy
* With one-way sync, the entire operation is idempotent, so simply re-running the sync after a partial failure is fine

## Implementation Notes

### Where to create new issues:

* Milestones, if any, are represented as projects in an Area, or if no Area, as projects in Next. Projects have due dates reflecting the milestone due date.
* Issues without a milestone are placed directly in the respective Area, or if no Area, into Next. (If updating an existing task, we won't move it back into Next, though.)

### Tag usage:

* When an issue task is created/updated, remove any extant "github:" tags, and apply "github:" tags that are currently on the issue.
* When creating/updating an issue task, add a "via:github" tag.
* Due dates for milestones are changed. We don't touch due dates or handle scheduling for tasks.

### Updating:

* Sync milestones as projects, creating them within the area or within Next; apply name, description, due date, tags as necessary. Mark closed milestones as complete, missing ones as cancelled, open ones as todo.
* Find all local tasks for this project; in toSync list
* For each open remote task assigned to me, update/create. Set name, state (todo, complete), tags. Move to proper area/project. Remove extant ones from toSync list.
* For each todo left in toSync, fetch it from the API. If it was unassigned to me, or otherwise is gone, cancel. If it was closed, complete.
* Descriptions are set to the URL on creation, but never modified.

### PR Handling:

* Same as issues
* Adds "(PR #xxx)" instead of "(#xxx)" to title

### Configuration:

* global: tag namespace (default "github"), github username
* per-project: github org/repo, things area
* on running, get current dir and walk up until I find a .thingshub file. error if I don't find one.
* merge with config from ~/.thingshubconfig ; local takes priority

### Identifying synced items:

* //thingshub/ORG/REPO/issue/###//
* //thingshub/ORG/REPO/milestone/###//

## Future features:

### 1.0

* config: look at ~ specifically first, then search current path; don't require current path to be in ~
* allow mapping github tag -> local tag (ie. in progress)
* allow adding prefix to project names
* select delegate (things/OF) via command line

### 1.1

* man page/interactive help
* allow logging out without manually changning keychain
* Use contacts/delegation for issues assigned to others.

## Contributors

Thanks to:

* [Andrew Sardone](https://github.com/andrewsardone/) - [@andrewa2](https://twitter.com/andrewa2)
