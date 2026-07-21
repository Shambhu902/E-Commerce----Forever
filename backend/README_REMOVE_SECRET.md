# Removing an exposed secret from git history

This document explains how to remove an accidentally committed secret (for example `backend/.env`) from the repository history and push a cleaned history to GitHub.

Important safety notes
- Immediately revoke or rotate the exposed credential in the provider dashboard (Stripe, AWS, etc.).
- Rewriting history will change commit SHAs; coordinate with collaborators.

Quick summary
1. Create a local backup branch (the script does this for you).
2. Use `git-filter-repo` to remove the file from all commits.
3. Verify the repository locally.
4. Force-push cleaned history to the protected branch (requires permission).

Files added
- `scripts/remove_secret.sh` — interactive script that:
  - creates a backup branch
  - adds the path to `.gitignore`
  - creates a `${path}.example` file with values redacted
  - runs `git filter-repo --invert-paths --path <path>` to remove the file
  - optionally force-pushes with `--force-with-lease` when you pass `--push`

How to run (example)
1. From the repo root:
```bash
cd /path/to/E-Commerce
chmod +x backend/scripts/remove_secret.sh
./backend/scripts/remove_secret.sh --path backend/.env
```

2. To perform the push automatically (only after you rotate keys and you understand effects):
```bash
./backend/scripts/remove_secret.sh --path backend/.env --push
```

If you cannot force-push due to branch protection, ask a repo admin to temporarily allow force pushes or to remove the blocked commit via the repository settings. After cleaning and pushing, rotate credentials again and verify that the secret no longer appears on GitHub using the Security -> Secret scanning view.

Alternatives
- Use BFG Repo-Cleaner for simpler cases: https://rtyley.github.io/bfg-repo-cleaner/
- Use GitHub's unblock workflow (less secure) via the link shown in the original push rejection message, but still rotate the credential.

Contact
If you'd like, I can run these steps here (will rewrite history and require force-push). Otherwise run the script locally and tell me if you want me to prepare the force-push commands for you.
