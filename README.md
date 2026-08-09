# GitHub Actions Learning Project

A deliberately small Flask app whose only real purpose is to give you something real to run a CI/CD pipeline against, one step at a time. Pair this with `../DevOps-Learning-Roadmap.md` and `LEARNING_STEPS.md` (in this folder).

## What's here

```
app/
  main.py              # tiny Flask app: "/" and "/health"
  requirements.txt      # runtime deps
  requirements-dev.txt   # test/lint deps
  tests/test_main.py    # a few pytest cases
  conftest.py, pytest.ini
Dockerfile               # multi-stage, non-root, with a HEALTHCHECK
.gitignore
LEARNING_STEPS.md         # copy these workflow snippets into .github/workflows/ one at a time
```

There is **no `.github/workflows/` file included on purpose** — the whole point of the exercise is that you add each workflow yourself, push it, and watch it run under your repo's **Actions** tab. Copying a finished pipeline in one shot skips the part that actually teaches you something.

## 1. Get this into your own GitHub repo

```bash
# from inside this folder
git init
git add .
git commit -m "Initial commit: starter app for GitHub Actions practice"
```

Then on github.com: create a new empty repository (no README/license — you already have files), copy the remote URL it gives you, and:

```bash
git remote add origin <your-repo-url>
git branch -M main
git push -u origin main
```

## 2. Run it locally first (before any CI)

```bash
cd app
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt -r requirements-dev.txt
pytest
python main.py   # visit http://localhost:8080 and http://localhost:8080/health
```

Confirm the tests pass and the app runs before you wire up CI — CI should confirm what you already know works, not be the first time you find out.

## 3. Turn on branch protection (Phase 0 of the roadmap)

Repo Settings → Branches → Add rule for `main` → require a pull request before merging, require status checks to pass. Do this *before* Step 1 below so you can actually watch a red check block a merge later.

## 4. Follow LEARNING_STEPS.md

Each step there is a small YAML addition plus what to expect when you push it. Do them in order — each one builds on the last, matching Phases 1–6 of the roadmap.
