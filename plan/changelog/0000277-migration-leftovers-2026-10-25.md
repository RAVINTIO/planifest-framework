# Changelog: 0000277 migration leftovers

## 2026-10-25 - Fast Path: the 0.37.0 migration cleans up the files 0.36.0 setup named

- Change: The rename helpers (`.sh` and `.ps1`) now clean up three installed files that kept their 0.36.0 form after the migration and a setup run:
  - Step 4 rewrites the old pack path in `.gitattributes`, so the LF rules cover `ravintio-framework/hooks/`.
  - Step 4 rewrites the old brand word in four workflow message phrases that 0.36.0 setup wrote.
  - Step 5 moves the old Cursor and Cline boot files into `.ravintio-backup/`, so the tools stop loading the old rules beside the new ones.
- Component: ravintio-framework, version 0.37.0 to 0.37.1
- Reason: Backlog 0000277. The human on the loop's manual test plan item on PR #71 ran the migration on a real 0.36.0 consumer and found these leftovers. PR #71 merged before the fix.
- Tests: `test-0000039-req-006-consumer-migration.sh` adds 31 checks per helper. `test-0000039-req-010-version-bump.sh` now accepts any 0.37 patch release, so a patch bump no longer fails it.
- History test: `test-0000039-req-005-history-and-split-name-protection.sh` compared with `merge-base HEAD origin/main`. Once PR #71 merged, that base already held the rename, so the suite failed on every new branch. When the merge base holds no old pack folder, the suite now compares with the parent of the commit that added `ravintio-framework/component.yml`.
- Backlog: this change closes 0000277 and removes its entry.
- Paths:
  - `ravintio-framework/migrations/migrate-0.37.0-ravintio-rename.sh`
  - `ravintio-framework/migrations/migrate-0.37.0-ravintio-rename.ps1`
  - `ravintio-framework/migrations/migrate-0.37.0-ravintio-rename.md`
  - `ravintio-framework/tests/test-0000039-req-006-consumer-migration.sh`
  - `ravintio-framework/tests/test-0000039-req-010-version-bump.sh`
  - `ravintio-framework/tests/test-0000039-req-005-history-and-split-name-protection.sh`
  - `ravintio-framework/component.yml`
  - `product.yml`
  - `docs/about.md`
