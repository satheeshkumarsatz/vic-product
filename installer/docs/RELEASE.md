# Release Procedures

All examples in this document assume the user's fork is at `origin` and `vmware/vic-product` is at
`upstream`.

## Branching

When the team is ready to build a release candidate, create a branch off of master based on the
release version number. A tag for ongoing development should also be created at the commit after
where the release branch begins. If there have been commits to master since the intended branch
point, first create a tag for the release candidate, then create the branch from that tag.

```
git remote update
git checkout upstream/master
# or
git checkout aaaaaaa
git checkout -b releases/1.2.0
git push upstream
```

Configure branch protection on Github to have the same protection as the master branch.
`Protect this branch` and `Require pull request reviews before merging` should be set.

Development should continue on master. Commits that need to be pulled into the release should be
cherry picked into the release branch after they are merged into master.

```
git remote update
git checkout releases/1.2.0
git rebase upstream/releases/1.2.0
git checkout -b cherry-pick-branch-name
git cherry-pick aaaaaaa
git push upstream
```


## Tagging

On the master branch, tag the commit for the first release candidate. On the
following commit, tag `dev` for ongoing development.  For example, if the
current release is `v1.2.0`, the first release candidate will be `v1.2.0-rc1` and
the tag for ongoing development will be `v1.3.0-dev`.

When the team is ready to release, tag the commit in the release branch (`v1.2.0`) and push the tag
to Github.

```
git remote update
git checkout upstream/releases/1.2.0
git tag -a v1.2.0-rc1 aaaaaaa
git push upstream v1.2.0-rc1
```

Tag `dev` on the release branch after a release. For example, if `v1.2.0` was tagged on
`/releases/1.2.0` and there is work for `v1.2.1`, on the following commit, tag `v1.2.1-dev`.

```
git remote update
git checkout upstream/releases/1.2.0
git tag -a v1.2.1-dev bbbbbbb
git push upstream v1.2.1-dev
```


## Building Release

```
git fetch --all --tags --prune
git checkout tags/v1.2.0
```

Follow instructions in [How to build VIC Product OVA](BUILD.md)

## Github Releases

After pushing the tag to Github, go to https://github.com/vmware/vic-product/releases/new

Select the appropriate tag

Title for follows form `VIC Product <tag>` (`VIC Product v1.2.0-rc1`)

Description template for release candidates:
```
OVA will contain:
Admiral `v1.2.0-rc3`
Harbor `harbor-offline-installer-v1.2.0-rc4.tgz`
VIC Engine `vic_1.2.0-rc4.tar.gz`
```

If the release is a release candidate, mark `This is a pre-release`

## OVA Releases

Description template for release version of the OVA:
```
Admiral `v1.2.0`
Harbor `harbor-offline-installer-v1.2.0.tgz`
VIC Engine `vic_1.2.0.tar.gz`

ef6b71d98bb6650240008b5281e97bf8592d5fd726833883718f471ed665fc5b  vic-v1.2.0-aaaaaaaa.ova
85eabdf7e58fed8c09e4f3c45b2caa974ae89a16  vic-v1.2.0-aaaaaaaa.ova
ebc669f7b4cebf7501cf141e3b6fa2e3  vic-v1.2.0-aaaaaaaa.ova
4741.43 MB
```
