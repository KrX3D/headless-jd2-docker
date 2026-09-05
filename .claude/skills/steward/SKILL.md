# PR Steward guidance for headless-jd2-docker

Repo-specific notes for a Claude session driving a PR on this repo to green.
This is guidance on conventions and proactivity, not permission to expand
scope: it never authorizes skipping/disabling tests, rewriting another
contributor's branch history, or merging/approving anything.

## Validating a fix before you push

- `alpine.Dockerfile` and `debian.Dockerfile` both download JDownloader at
  build time and run it once to seed config, so a build takes real time —
  don't assume a change is safe without actually building the affected
  image(s).
- The repo's own local validation is `./build-n-test.sh`: it builds both
  images and runs the three `goss` suites (`tests/default`,
  `tests/uid-test`, `tests/credentials-test`) against each via `dgoss`.
  `dgoss` isn't installed by default — see
  https://github.com/goss-org/goss/blob/master/extras/dgoss/dgoss and
  https://goss.rocks/install.
- CI (`.github/workflows/build.yml`, `build` job) runs the same three goss
  suites against both images on every push and PR. Both suites must pass
  for both images — a fix that only helps one image/suite isn't done.

## Known CI-timing sensitivity

`dgoss run` sleeps `GOSS_SLEEP` (default 0.2s) after starting the
container before asserting anything. `common/entrypoint.sh` does real work
as root before dropping privileges — user/group creation, writing the
MyJDownloader credentials file, and a conditional `chown -R` — which can
occasionally take longer than the default sleep on a loaded runner. If a
goss assertion (e.g. "user jdownloader: exists") fails with no obvious
code-level cause, suspect timing before suspecting the container: try
reproducing with a larger `GOSS_SLEEP` (e.g. `GOSS_SLEEP=1`) before
concluding anything, and if that's the actual cause, fix it by raising
`GOSS_SLEEP` in the workflow rather than retrying blindly or declaring it
a flake.

## Conventions

- History merges PRs with GitHub's default merge commits ("Merge pull
  request #N from ..."). On a merge conflict, merge `master` into the PR
  branch — don't rebase or squash a branch you don't own.
- No lockfiles or other generated files live in this repo; a fix is just
  the Dockerfile / `entrypoint.sh` / workflow diff itself, nothing to
  regenerate.
- `UID`/`GID`/`EMAIL`/`PASSWORD`/`UMASK` are the only environment
  variables the entrypoint reads — check `README.md`'s environment
  variable table stays accurate whenever one of these changes behavior.
