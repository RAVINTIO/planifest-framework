#!/usr/bin/env bash
# migrate-0.37.0-ravintio-rename.sh - move a consumer repo to the RAVINTIO names.
# Run it from the project root, after you copy ravintio-framework/ in and
# before you run ravintio-framework/setup.sh. The project root may sit below
# the git top level.
#
# The helper deletes no file except the one session marker. It moves the old
# pack into .ravintio-backup/ with a plain rename, which moves a nested link as
# a link and follows none. Every step skips work that is already done, so a
# rerun is safe. A run stopped after any step resumes on the next run.
#
# The .ps1 twin prints the same text and exits with the same codes:
#   0  done, or nothing to do
#   1  stopped before a move, or a move failed
#   3  stopped by the test hook RAVINTIO_MIGRATE_STOP_AFTER=N
#
# The old brand word is built from parts so this file holds no literal copy.

set -uo pipefail

OLD="plan""ifest"
OLDU="PLAN""IFEST"
NEW_PACK="ravintio-framework"
OLD_PACK="$OLD-framework"
OLD_OVR="$OLD-overrides"
NEW_OVR="ravintio-overrides"
WF_DIR=".github/workflows"
OLD_WF="$WF_DIR/$OLD.yml"
NEW_WF="$WF_DIR/ravintio.yml"
BACKUP=".ravintio-backup"
SESSION=".claude/.$OLD-session"
STOP_AFTER="${RAVINTIO_MIGRATE_STOP_AFTER:-}"

# Pack-owned variable names (the req-003 inventory, retired telemetry names
# left out). Step 4 rewrites these whole names and no other.
PACK_VARS="ADAPTER_CMD BASENAME BOOT DESIGN EM_DASH FILE_PATH GATE GITLEAKS HOOKS_BASE NAME OPENCODE_JSON PLUGIN_REF PRESENCE RATCHET SETTINGS SETTINGS_JS_HELPERS SETTINGS_REL SHELL_GUARD TIER TMP TRIGGER PROMOTED_BY PROMOTION_DATE REGRESSION_DIR SOURCE_FEATURE SHARD_INDEX SHARD_COUNT SESSION_ID"

MOVED=""
CHANGED=0

note_moved() {
    MOVED="${MOVED}  $1
"
}

print_moved() {
    if [ -z "$MOVED" ]; then
        echo "Moved so far: nothing."
    else
        echo "Moved so far:"
        printf '%s' "$MOVED"
    fi
}

# stop_at N MESSAGE: stop with exit 1.
stop_at() {
    echo "ERROR: $2"
    echo "Stopped at step $1."
    print_moved
    exit 1
}

# hook N: the test hook stops the run right after step N with exit 3.
hook() {
    if [ "$STOP_AFTER" = "$1" ]; then
        echo "Stopped at step $1 (RAVINTIO_MIGRATE_STOP_AFTER)."
        print_moved
        exit 3
    fi
}

present() { [ -e "$1" ] || [ -L "$1" ]; }

IN_GIT=0
if command -v git >/dev/null 2>&1 \
   && [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = "true" ]; then
    IN_GIT=1
fi

tracked() {
    [ "$IN_GIT" -eq 1 ] && [ -n "$(git ls-files -- "$1" 2>/dev/null)" ]
}

# move_path SRC DST STEP: git mv when git tracks SRC, else a plain rename.
move_path() {
    if tracked "$1"; then
        git mv "$1" "$2" >/dev/null 2>&1 || stop_at "$3" "could not move $1 to $2."
    else
        mv "$1" "$2" || stop_at "$3" "could not move $1 to $2."
    fi
}

# first_link PATH...: print the first path that is a link, if any.
first_link() {
    local p
    for p in "$@"; do
        if [ -L "$p" ]; then
            echo "$p"
            return 0
        fi
    done
    return 0
}

# rewrite_names FILE: print FILE with the pack path and the pack-owned
# variable names rewritten. A name counts only as a whole name.
rewrite_names() {
    awk -v op="$OLD_PACK/" -v np="$NEW_PACK/" -v old="${OLDU}_" -v new="RAVINTIO_" -v names="$PACK_VARS" '
    function isword(c) { return c ~ /[A-Za-z0-9_]/ }
    BEGIN { n = split(names, nm, " ") }
    {
        line = $0
        out = ""
        while ((i = index(line, op)) > 0) {
            out = out substr(line, 1, i - 1) np
            line = substr(line, i + length(op))
        }
        line = out line
        for (k = 1; k <= n; k++) {
            w = old nm[k]
            out = ""
            while ((i = index(line, w)) > 0) {
                pre = (i > 1) ? substr(line, i - 1, 1) : substr(out, length(out), 1)
                post = substr(line, i + length(w), 1)
                if ((pre == "" || !isword(pre)) && (post == "" || !isword(post))) {
                    out = out substr(line, 1, i - 1) new nm[k]
                } else {
                    out = out substr(line, 1, i - 1 + length(w))
                }
                line = substr(line, i + length(w))
            }
            line = out line
        }
        print line
    }' "$1"
}

# Step 1: the new pack must be in place.
if [ ! -d "$NEW_PACK" ]; then
    stop_at 1 "$NEW_PACK/ not found. Copy the new $NEW_PACK/ folder into this project, then run this helper again."
fi
echo "Step 1: found $NEW_PACK/."
hook 1

# Step 2: check every stop condition before the first move.
WF_PARENT_LINK="$(first_link ".github" "$WF_DIR")"
LINK_CHECKS="$OLD_PACK $OLD_OVR $NEW_OVR $BACKUP"
if [ -z "$WF_PARENT_LINK" ]; then
    LINK_CHECKS="$LINK_CHECKS $OLD_WF $NEW_WF"
fi
for p in $LINK_CHECKS; do
    if [ -L "$p" ]; then
        stop_at 2 "$p is a symlink or junction. The helper leaves it and its target untouched. Replace it with a real file or folder, then run this helper again."
    fi
done
if present "$OLD_OVR" && present "$NEW_OVR"; then
    stop_at 2 "both $OLD_OVR/ and $NEW_OVR/ exist. Merge them into $NEW_OVR/ by hand, then run this helper again."
fi
if [ -z "$WF_PARENT_LINK" ] && present "$OLD_WF" && present "$NEW_WF"; then
    stop_at 2 "both $OLD_WF and $NEW_WF exist. Keep one of them, then run this helper again."
fi
if present "$BACKUP" && [ ! -d "$BACKUP" ]; then
    stop_at 2 "$BACKUP exists and is not a folder. Move it aside, then run this helper again."
fi
if present "$BACKUP/$OLD_PACK" && present "$OLD_PACK"; then
    stop_at 2 "$BACKUP/$OLD_PACK/ exists while $OLD_PACK/ is still in place. Check the older backup and move it aside, then run this helper again."
fi
if [ "$IN_GIT" -eq 1 ] && ! git diff --cached --quiet --diff-filter=ACMRT -- "$OLD_PACK" >/dev/null 2>&1; then
    stop_at 2 "git holds a staged edit under $OLD_PACK/. Commit it or unstage it, then run this helper again."
fi
echo "Step 2: no stop condition found."
hook 2

# Step 3: move the overrides folder.
if [ -d "$OLD_OVR" ]; then
    move_path "$OLD_OVR" "$NEW_OVR" 3
    echo "Step 3: moved $OLD_OVR/ to $NEW_OVR/."
    note_moved "$OLD_OVR/ to $NEW_OVR/"
    CHANGED=1
else
    echo "Step 3: skipped, $OLD_OVR/ is not present."
fi
hook 3

# Step 4: rename the workflow and rewrite the pack-owned names in it.
if [ -n "$WF_PARENT_LINK" ]; then
    echo "WARNING: $WF_PARENT_LINK is a symlink. Skipped step 4, so nothing is written through it."
else
    if [ -f "$OLD_WF" ]; then
        move_path "$OLD_WF" "$NEW_WF" 4
        echo "Step 4: renamed $OLD_WF to $NEW_WF."
        note_moved "$OLD_WF to $NEW_WF"
        CHANGED=1
    else
        echo "Step 4: skipped the rename, $OLD_WF is not present."
    fi
    if [ -f "$NEW_WF" ]; then
        if rewrite_names "$NEW_WF" | cmp -s - "$NEW_WF"; then
            echo "Step 4: skipped the rewrite, $NEW_WF holds no pack-owned old name."
        else
            # Write to a temporary file in the same folder, then rename it
            # over the target.
            TMP="$(mktemp "$WF_DIR/.ravintio.yml.XXXXXX")" || stop_at 4 "could not create a temporary file in $WF_DIR/."
            rewrite_names "$NEW_WF" > "$TMP" || stop_at 4 "could not rewrite $NEW_WF. The temporary file $TMP is left for you to check."
            chmod 644 "$TMP"
            mv -f "$TMP" "$NEW_WF" || stop_at 4 "could not replace $NEW_WF. The temporary file $TMP is left for you to check."
            echo "Step 4: rewrote the pack path and pack-owned names in $NEW_WF."
            CHANGED=1
        fi
    fi
fi
hook 4

# Step 5: remove the session marker. Setup removes the other two markers.
CLAUDE_LINK="$(first_link ".claude")"
if [ -n "$CLAUDE_LINK" ]; then
    echo "WARNING: .claude is a symlink. Skipped the marker under it, so nothing is removed through it."
else
    if [ -L ".claude/skills" ]; then
        echo "WARNING: .claude/skills is a symlink. Skipped the marker under it, so nothing is written through it."
    fi
    if [ -L "$SESSION" ]; then
        echo "WARNING: $SESSION is a symlink. Left it in place."
    elif [ -f "$SESSION" ]; then
        rm -f "$SESSION" || stop_at 5 "could not remove $SESSION."
        echo "Step 5: removed $SESSION."
        CHANGED=1
    elif present "$SESSION"; then
        echo "WARNING: $SESSION is not a regular file. Left it in place."
    else
        echo "Step 5: skipped, $SESSION is not present."
    fi
fi
hook 5

# Step 6: stop git tracking of the old pack, then rename it into the backup.
if [ -d "$OLD_PACK" ]; then
    if tracked "$OLD_PACK"; then
        git rm -r -q --cached -- "$OLD_PACK" >/dev/null 2>&1 || stop_at 6 "could not stop git tracking of $OLD_PACK/."
    fi
    mkdir -p "$BACKUP" || stop_at 6 "could not create $BACKUP/."
    mv "$OLD_PACK" "$BACKUP/$OLD_PACK" || stop_at 6 "could not move $OLD_PACK/ to $BACKUP/$OLD_PACK/."
    echo "Step 6: moved $OLD_PACK/ to $BACKUP/$OLD_PACK/."
    note_moved "$OLD_PACK/ to $BACKUP/$OLD_PACK/"
    CHANGED=1
else
    echo "Step 6: skipped, $OLD_PACK/ is not present."
fi
if [ "$IN_GIT" -eq 1 ] && [ -d "$BACKUP" ]; then
    EXCLUDE="$(git rev-parse --git-path info/exclude 2>/dev/null)"
    INFO_DIR="$(dirname "$EXCLUDE")"
    if [ -L "$INFO_DIR" ] || [ -L "$EXCLUDE" ]; then
        echo "WARNING: $EXCLUDE or its folder is a symlink. Skipped adding $BACKUP/ to it."
    elif [ -f "$EXCLUDE" ] && grep -qxF "$BACKUP/" "$EXCLUDE"; then
        :
    else
        mkdir -p "$INFO_DIR" || stop_at 6 "could not create $INFO_DIR."
        if [ -s "$EXCLUDE" ] && [ -n "$(tail -c 1 "$EXCLUDE")" ]; then
            echo >> "$EXCLUDE"
        fi
        echo "$BACKUP/" >> "$EXCLUDE" || stop_at 6 "could not write $EXCLUDE."
        echo "Step 6: added $BACKUP/ to $EXCLUDE."
        CHANGED=1
    fi
fi
hook 6

if [ "$CHANGED" -eq 0 ]; then
    echo "Nothing to do. This project already uses the RAVINTIO names."
fi

# Step 7: the next step.
echo "Next step: run $NEW_PACK/setup.sh claude-code, or setup.ps1, or the tool this project uses, before the next commit."
if [ -d "$BACKUP/$OLD_PACK" ]; then
    echo "The old pack is in $BACKUP/$OLD_PACK/. Delete $BACKUP/ after you check that nothing of yours is in it."
fi
hook 7

# Step 8: branch protection.
echo "WARNING: a branch protection rule that requires the old check name must now require RAVINTIO Strict Pipeline."
hook 8

exit 0
