# Build the pipeline yourself, one commit at a time

For each step: create/edit the file shown, commit, push, then open the **Actions** tab on GitHub and watch it run. Read what actually happened before moving to the next step — the log output is most of the learning here.

---

## Step 1 — Your first workflow (Phase 1)

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  hello:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: echo "Pipeline is alive. Commit was ${{ github.sha }}"
```

Push it. Open **Actions** → click the run → click the job → expand the step. That log line with your commit SHA is proof the runner actually checked out your code.

**Try breaking it on purpose:** rename `runs-on: ubuntu-latest` to `runs-on: nonexistent-runner`, push, and read the error GitHub gives you. Then revert it. Learning to read a failed-run error is as important as writing the YAML.

---

## Step 2 — Run the real tests (Phase 2)

Replace the `hello` job with a `test` job:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: app
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
          cache: 'pip'
          cache-dependency-path: app/requirements*.txt
      - run: pip install -r requirements.txt -r requirements-dev.txt
      - run: pytest
```

Push it — should go green. Now open `app/tests/test_main.py`, change `assert add(2, 3) == 5` to `== 6`, push on a branch, open a PR. Watch the check fail on the PR itself, not just in the Actions tab. Fix it, push again, watch it flip green. This red→green loop on a PR is the single most common thing you'll do in a DevOps/dev role.

---

## Step 3 — Add linting as its own job (Phase 2)

Add a second job that runs alongside `test` (not after it — independent checks should run in parallel):

```yaml
  lint:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: app
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - run: pip install -r requirements-dev.txt
      - run: ruff check .
```

Push. You should see `test` and `lint` running side by side in the Actions UI, not one after the other — that's what having no `needs:` between them buys you.

---

## Step 4 — Build the Docker image + scan it (Phase 3)

Add a `build` job that only runs after `test` and `lint` both pass:

```yaml
  build:
    needs: [test, lint]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/build-push-action@v5
        with:
          context: .
          push: false
          tags: learning-app:${{ github.sha }}
          load: true
      - name: Scan image for vulnerabilities
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: learning-app:${{ github.sha }}
          severity: 'CRITICAL,HIGH'
          exit-code: '0'   # set to '1' once you're ready to actually block on findings
```

`needs: [test, lint]` is what makes this wait — try removing it and notice `build` starts immediately instead of waiting.

---

## Step 5 — Push to GitHub Container Registry, tagged properly (Phase 4)

Update the `build` job to actually push, but only from `main`:

```yaml
  build:
    needs: [test, lint]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/${{ github.repository }}
          tags: |
            type=sha,prefix=
            type=raw,value=latest,enable=${{ github.ref == 'refs/heads/main' }}
      - uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

Merge a PR into `main` and check the repo's **Packages** tab (right sidebar on the repo homepage) for the image, tagged with the commit SHA.

Note this only runs the push on `main` — open a PR from a branch and confirm the `build` job is skipped (not failed) on that PR, per the `if:` condition.

---

## Step 6 — Environments, secrets, and a manual approval gate (Phase 5–6)

In repo Settings → Environments, create `staging` and `production`. On `production`, add yourself as a required reviewer. Add a dummy secret called `DEPLOY_TOKEN` to each (any placeholder value).

```yaml
  deploy-staging:
    needs: build
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - run: echo "Deploying ${{ needs.build.outputs.image-tag }} to staging"
        env:
          DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}
      - name: Smoke test
        run: curl -f https://your-staging-url/health || exit 1

  deploy-production:
    needs: deploy-staging
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - run: echo "Deploying to production"
        env:
          DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}
```

Push to `main` and watch the run pause at `deploy-production`, waiting for your approval click in the Actions UI. That pause — not the `echo` command — is the actual lesson here: it's how teams put a human checkpoint in front of anything customer-facing.

Once you've wired `deploy-staging` to a real target (Fly.io, Render, GitHub Pages — see Phase 6 of the roadmap), replace the `echo`/`curl` placeholders with the real deploy command and a real health-check URL.

---

## What "done" looks like

By the end of Step 6 you have, in your own GitHub account: a PR that gets blocked by a failing check, a Docker image built and scanned on every push, an image published to GHCR only from `main`, and a deploy that pauses for your approval before hitting "production." That's the whole shape of a real pipeline — everything past this point (Kubernetes, Terraform, real cloud targets) is the same pattern applied to bigger infrastructure.
