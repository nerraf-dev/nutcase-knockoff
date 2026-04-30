# GitHub Issue Automation (Git Bash)

This setup lets you create a batch of GitHub issues from a seed file.

## Files
- Seed data: tiled-docs/github-issues/issues-seed.tsv
- Script: tiled/tools/github/create_issues_from_seed.sh

## Requirements
- Git Bash
- GitHub CLI (`gh`) installed
- Authenticated session: `gh auth login`

## Run in Git Bash
From repository root:

```bash
cd /c/Users/sifar/repos/nutcase-knockoff/tiled
DRY_RUN=1 ./tools/github/create_issues_from_seed.sh LittleCogWorks/tiled ../tiled-docs/github-issues/issues-seed.tsv
```

If the dry run looks right, create issues for real:

```bash
cd /c/Users/sifar/repos/nutcase-knockoff/tiled
DRY_RUN=0 ./tools/github/create_issues_from_seed.sh LittleCogWorks/tiled ../tiled-docs/github-issues/issues-seed.tsv
```

## Notes
- Duplicate titles are skipped automatically.
- Labels are read from the TSV and added per issue.
- Edit the TSV to change titles, labels, summaries, or acceptance criteria.
