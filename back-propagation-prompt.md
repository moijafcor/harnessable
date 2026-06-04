You are syncing all harnessable installations to the latest framework.

```
FRAMEWORK_ROOT=~/code/harnessable
```

## Step 0 — Confirm install.sh is current

```sh
cd $FRAMEWORK_ROOT
git log --oneline -3
echo "install.sh: $(wc -l < install.sh) lines"
```

## Step 1 — Discover all installations

```sh
find ~/code -name "HARNESSABLE_VERSION" \
    -path "*/vendor/harnessable/HARNESSABLE_VERSION" \
    -not -path "*/harnessable/framework/*" \
    2>/dev/null | while read f; do
  PROJECT=$(dirname $(dirname $(dirname $(dirname $f))))
  PINNED=$(cat $f)
  CURRENT=$(git -C $FRAMEWORK_ROOT rev-parse --short HEAD)
  echo "PROJECT=$PROJECT | pinned=$PINNED | current=$CURRENT"
done
```

## Step 2 — Sync each installation

For each discovered project, run:

```sh
bash $FRAMEWORK_ROOT/install.sh --update $PROJECT_ROOT
```

Complete one project before moving to the next.
Do not proceed if a project has a dirty working tree —
`install.sh --update` will detect and halt.

## Step 3 — Review and commit each project

```sh
git -C $PROJECT_ROOT status
git -C $PROJECT_ROOT add -A
git -C $PROJECT_ROOT commit -m \
  "chore: sync harnessable → $(git -C $FRAMEWORK_ROOT rev-parse --short HEAD)"
```

## Final report

| Project | Result | MERGE needed | REPLACE remaining |
|---------|--------|:------------:|:-----------------:|
| (fill from install.sh output per project) | | | |
