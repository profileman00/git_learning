# Your GitHub + GitHub Actions Roadmap to DevOps

**For:** Charles — Git basics known, new to GitHub collaboration and Actions, aiming for a DevOps career switch
**Format:** Hands-on, project-first. Every phase produces something real in a GitHub repo you can point to later.
**Pace:** Written as 7 phases rather than fixed weeks — move at whatever speed fits your schedule, but don't skip the "build" step in each one. Reading about CI/CD without pushing a commit that triggers a pipeline doesn't stick.

Companion project: the `github-actions-learning-project` folder delivered alongside this roadmap. It's a small Flask app with tests, a Dockerfile, and a `LEARNING_STEPS.md` that walks you through building the pipeline for it one commit at a time. Phases 2–6 below map directly onto that project.

---

## Phase 0 — GitHub itself (not just Git)

You already know commits, branches, and merges locally. What's new is GitHub's collaboration layer, and that's what interviewers and teams actually care about.

Do this:
- Create a repo from the companion project (instructions in its README) and push it.
- Open a pull request against your own `main` branch from a feature branch, even solo — get comfortable with the PR diff view, review comments, and "Squash and merge" vs "Merge commit."
- Turn on branch protection on `main` (Settings → Branches): require a PR before merging, require status checks to pass. This one setting is why CI matters — a red check should be able to physically block a bad merge.
- File an Issue, reference it from a commit message (`Fixes #1`), and watch GitHub auto-close it on merge.
- Read GitHub's own docs on pull requests and branch protection rather than a video course — they're short and exactly on point: https://docs.github.com/en/pull-requests and https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository

Checkpoint: you can explain, in your own words, why a team requires PR review + passing checks before merge, and you've done it once yourself.

---

## Phase 1 — GitHub Actions fundamentals

Core concepts before touching YAML:
- **Workflow** — a YAML file in `.github/workflows/`, triggered by events (`push`, `pull_request`, `schedule`, `workflow_dispatch`).
- **Job** — a set of steps that runs on one runner (a fresh VM). Jobs run in parallel by default; use `needs:` to sequence them.
- **Step** — either a shell command (`run:`) or a reusable **Action** (`uses:`) pulled from the Marketplace.
- **Runner** — the VM executing the job (`ubuntu-latest`, `macos-latest`, or your own self-hosted machine).

Do this:
- Read GitHub's "Understanding GitHub Actions" doc: https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions
- In the companion project, add the very first workflow from `LEARNING_STEPS.md` (Step 1) — it just checks out code and echoes a message. Push it, watch it run under the repo's **Actions** tab. This is the whole feedback loop you'll use for everything after.

Checkpoint: you can look at any `.github/workflows/*.yml` file on GitHub and correctly name what triggers it, how many jobs it has, and what order they run in.

---

## Phase 2 — Real CI: tests + linting

This is where Actions starts paying for itself: every push gets automatically checked.

Do this (companion project, `LEARNING_STEPS.md` Step 2–3):
- Add a job that installs dependencies and runs `pytest`.
- Add a linting step (`ruff` or `flake8`) as a separate step or job — decide whether a lint failure should block merge (it should, in a real team).
- Break a test on purpose, push it, and watch the PR check go red. Then fix it and watch it go green. Seeing both directions matters more than it sounds like it would.
- Add dependency caching (`actions/cache@v4`) so installs don't re-download every run.

Checkpoint: a PR with a failing test shows a red ✗ next to the commit and (if you turned on the Phase 0 branch protection) the merge button is disabled.

---

## Phase 3 — Containerize the app

Do this:
- Write a Dockerfile for the Flask app (a starter is already in the companion project — read it, don't just trust it).
- Build and run it locally: `docker build -t learning-app . && docker run -p 8080:8080 learning-app`.
- Add a CI job that builds the image on every push, so a broken Dockerfile fails CI the same way a broken test does.
- Add `aquasecurity/trivy-action` to scan the built image for known vulnerabilities — this is a standard real-world gate, not busywork.

Checkpoint: you can explain what each line of your Dockerfile does and why the image is built in a separate CI job from the test job.

---

## Phase 4 — Push to a registry, tag properly

Do this:
- Log in to GHCR (GitHub Container Registry) from Actions using the automatic `GITHUB_TOKEN` — no separate secret needed for your own repo.
- Use `docker/metadata-action` to tag images with both the git SHA and the branch name, never just `latest`.
- Push the image on merges to `main` only, not on every PR (use an `if:` condition on the job).

Checkpoint: after merging a PR, you can find the resulting image in your repo's **Packages** tab with a tag matching that commit's SHA.

---

## Phase 5 — Environments, secrets, and approval gates

This phase is what separates "I made a pipeline" from "I understand how teams ship safely."

Do this:
- Create a `staging` and a `production` **Environment** in repo Settings → Environments.
- Add a required reviewer to `production` — this makes GitHub pause the workflow and wait for a human click before that job runs.
- Store a fake secret (e.g., `DEPLOY_TOKEN=dummy`) in each environment's secrets, and reference it in a step — notice it never appears in logs even if you try to print it.
- Split your deploy job into `deploy-staging` (auto, on `develop`/`main` push) and `deploy-production` (needs manual approval).

Checkpoint: you can trigger a run that stops and waits for your approval before the "production" step executes, and you understand why secrets belong in Environments/Settings, never in the YAML file itself.

---

## Phase 6 — Actually deploy something

Pick one free target so "deploy" isn't just a `kubectl` command against nothing:
- **Fly.io** or **Render** (free tier) for the Flask app — both have GitHub Actions integrations.
- **GitHub Pages** if you'd rather practice on a static site first — simplest possible real deployment.

Do this:
- Wire the `deploy-staging` job to actually deploy to your chosen platform.
- Add a smoke test step after deploy: a `curl -f` against the live health endpoint that fails the workflow if the app didn't come up.
- Write the rollback procedure down (even for a toy app) — what command undoes this deploy? This is the habit that matters most on the job.

Checkpoint: pushing to your repo results in a live URL that actually updates, with an automated check that would have caught it if it hadn't.

---

## Phase 7 — Capstone for your portfolio

Take everything above and apply it to a project that isn't the throwaway Flask app — ideally something you already have, or a small tool you build specifically to showcase this. Requirements for it to function as a portfolio piece:

- Full pipeline: lint → test → build → scan → push → deploy-staging → (approval) → deploy-production.
- A README section titled "CI/CD Pipeline" that explains the workflow diagram in plain language — hiring managers skim READMEs, they don't read YAML.
- At least one matrix build (e.g., testing against two Python versions) to show you know the pattern.
- A documented rollback command, per the skill's convention: `kubectl rollout undo ...` or the equivalent for wherever you deployed.

This repo — not a certificate — is what you link from your resume and LinkedIn when you say "DevOps" as a target role.

---

## Where GitHub Actions fits in the bigger DevOps picture

GitHub Actions is the CI/CD layer. A DevOps role usually also touches:

- **Containers** — Docker (you'll have this from Phase 3) and Kubernetes for orchestration at scale.
- **Infrastructure as Code** — Terraform, so environments are defined in version-controlled code rather than clicked together in a console.
- **Observability** — Prometheus/Grafana or a hosted equivalent, for knowing when production is unhealthy.
- **Incident response** — on-call practices, runbooks, postmortems.

You don't need all of that to start applying — Phases 0–7 above already make a credible junior DevOps/platform portfolio piece. But once you're comfortable with this roadmap, ask for the same kind of hands-on plan for Docker → Kubernetes → Terraform next; those references are ready to go.

## Reference docs worth bookmarking

- GitHub Actions documentation: https://docs.github.com/en/actions
- GitHub Actions Marketplace (browse existing actions before writing custom steps): https://github.com/marketplace?type=actions
- `docker/build-push-action`, `docker/metadata-action`, `actions/cache` — the three actions you'll reuse constantly, all referenced above.
