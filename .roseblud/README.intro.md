# 🌹 Tinycast Roseblud Edition

**Tinycast Roseblud Edition** is a personal, automatically synced fork of
**[Tinycast Space Edition](https://github.com/sermelipharo/tinycast-space)**, itself a fork of
**[Tinycast](https://github.com/abue-ammar/tinycast)** by [Abue Ammar](https://github.com/abue-ammar).
It has everything Space Edition has, plus the few changes below.

Download it from this repository's **[Releases](https://github.com/coledeb/tinycast-roseblud/releases)**;
the steps are the same as in the [Install](#install) section below. Installed copies update themselves
from here.

Nothing this fork automates posts to the original repositories: the automation only writes here, and
the commit messages it copies from upstream have their issue and pull-request links removed, so no
build or release here shows up on an upstream issue.

GitHub shows this fork as commits "behind" Space Edition even when it's up to date. That's because
upstream issue links are removed from Space Edition's commit messages, as
[Tinycast's contributing guide](https://github.com/abue-ammar/tinycast/blob/main/CONTRIBUTING.md#spam)
asks, and editing a message changes the commit's ID.

## What Roseblud adds

<!-- roseblud:changes -->

## Beta channel

Tinycast publishes betas between releases, but Space Edition doesn't build them, so this fork builds
its own. Each [upstream beta](https://github.com/abue-ammar/tinycast/releases) is released here as a
**pre-release** with the same tag and version (e.g. `v0.13.0-beta.145`), built from this fork's
`main` once `main` includes it, so it has everything that beta has plus Space Edition's and Roseblud's
changes.

To get them, open **Settings → About → Update Channel** and pick **Beta**. Tinycast then updates to
each new beta, and to any newer release once it ships, so a beta always leads on to its release.
Pick **Stable** to go back: you stay on the installed beta until a release newer than it is out,
then get releases only. Unlike upstream's separate *Tinycast Beta* app, it is the same app either
way, so betas share your settings and data; expect the occasional rough edge.

---

> Everything below is Space Edition's README, kept as it is apart from its Releases and Issues links,
> which point here.

