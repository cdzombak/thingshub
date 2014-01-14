# ThingsHub

Synchronize issues assigned to you, one-way, from a Github repo into Things.

*A more complete README, featuring complete sentences, is forthcoming.*

## Implementation Notes

### Where to create new issues:

* Milestones, if any, are represented as projects in an Area, or if no Area, as projects in Next. Projects have due dates reflecting the milestone due date.
* Issues without a milestone are placed directly in the respective Area, or if no Area, into the Inbox.

### Tag usage:

* When a project or issue task is created or modified in any way, apply the tag "review". Allow configuring this tag.
* When an issue task is created/updated, remove any extant "github:" tags, and apply "github:" tags that are currently on the issue.
* When creating/updating an issue task, add a "via:github" tag.
* Due dates for milestones are changed. We don't touch due dates or handle scheduling for tasks.

### Updating:

* Sync milestones as projects, creating them within the area or within Next; apply name, description, due date, tags as necessary. Mark closed milestones as complete, missing ones as cancelled, open ones as todo.
* Find all local tasks for this project; in toSync list
* For each open remote task assigned to me, update/create/mark for review. Set name, state (todo, complete), tags. Move to proper area/project. Remove extant ones from toSync list.
* For each todo left in toSync, fetch it from the API. If it was unassigned to me, or otherwise is gone, cancel. If it was closed, complete. Mark for review.
* Descriptions are set to the URL on creation, but never modified.

### PR Handling:

* Same as issues
* Does not import PRs you created and assigned to yourself (assumes it's a WIP)
* Adds "(PR #xxx)" instead of "(#xxx)" to title

### Configuration:

* global: tag namespace (default "github"), review tag (default "review"), github username
* per-project: github org/repo, things area
* on running, get current dir and walk up until I find a .thingshub file. error if I don't find one.
* merge with config from ~/.thingshubconfig ; local takes priority

### Identifying synced tasks:

* //thingshub/ORG/REPO/###//

## Workflow notes:

* brew this shit; goes in /usr/local/bin
* This never updates Github from Things; GH is the canonical source of truth.
* This will always create issues in Next, except for issues that have no area *or* project. You can move to Today/Someday as desired.
* This *will* move issues to areas/projects to reflect milestone changes. This doesn't touch Today/Next/Someday.

### Why GitHub as the source of truth?

* Issues may be modified by many people, vastly increasing the chance of conflicts
* Conflict management is easy this way, and we probably won't lose much data
* Issues are usually closed as side effects of other operations (merges, commits) anyway
* Descriptions are often used in Things for personal notes
* You don't want your local tags DB to reflect 1:1 Github - too noisy

## Future features:

* allow mapping github tag -> local tag (ie. in progress)
* man page/interactive help
* allow logging out without manually changning keychain
* Use contacts/delegation for issues assigned to others.
* OmniFocus should allow similar implementation

## Allowed configuration keys

```objc
    @"tagNamespace": NSStringFromSelector(@selector(tagNamespace)),
    @"reviewTag": NSStringFromSelector(@selector(reviewTagName)),
    @"githubLogin": NSStringFromSelector(@selector(githubLogin)),
    @"githubOrg": NSStringFromSelector(@selector(githubOrgName)),
    @"githubRepo": NSStringFromSelector(@selector(githubRepoName)),
    @"thingsArea": NSStringFromSelector(@selector(thingsAreaName)),
```
