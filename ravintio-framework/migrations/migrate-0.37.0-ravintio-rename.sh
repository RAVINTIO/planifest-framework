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
OLDC="Plan""ifest"
# Step 4 rewrites this workflow name line when it matches the whole line.
OLD_WF_NAME="name: $OLDC Strict Pipeline"
NEW_WF_NAME="name: RAVINTIO Strict Pipeline"
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
# Step 5 renames the markers in each of these tool folders.
TOOL_DIRS=".claude .cursor .windsurf .clinerules .agents .github .gemini .opencode"
OLD_FLAGS=".$OLD-setup-flags"
NEW_FLAGS=".ravintio-setup-flags"
OLD_MANIFEST=".$OLD-manifest"
NEW_MANIFEST=".ravintio-manifest"
# Step 7 prints a saved tool only when setup accepts it.
SETUP_TOOLS="claude-code cursor codex antigravity copilot windsurf cline roo-code opencode"

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

# stop_if_present DST STEP: stop when DST appeared after the step 2 check,
# because mv and git mv would move the source inside it.
stop_if_present() {
    if present "$1"; then
        stop_at "$2" "$1 appeared after step 2. Move it aside, then run this helper again."
    fi
}

# move_path SRC DST STEP: git mv when git tracks SRC, else a plain rename.
move_path() {
    local use_git=0
    if tracked "$1"; then use_git=1; fi
    stop_if_present "$2" "$3"
    if [ "$use_git" -eq 1 ]; then
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

# marker_link DIR: print DIR/skills or the first marker file in DIR that is a
# link, if any.
marker_link() {
    first_link "$1/skills" "$1/$OLD_FLAGS" "$1/$NEW_FLAGS" "$1/skills/$OLD_MANIFEST" "$1/skills/$NEW_MANIFEST"
}

# marker_skip DIR: true when step 5 leaves the markers in DIR alone. That is
# when DIR is not a real folder, or DIR/skills or a marker file is a link.
marker_skip() {
    if [ ! -d "$1" ] || [ -L "$1" ]; then return 0; fi
    [ -n "$(marker_link "$1")" ]
}

# rename_marker SRC DST: step 5 renames the marker file SRC to DST, or warns
# when SRC is present but not a regular file.
rename_marker() {
    if [ -f "$1" ]; then
        move_path "$1" "$2" 5
        echo "Step 5: renamed $1 to $2."
        note_moved "$1 to $2"
        CHANGED=1
    elif present "$1"; then
        echo "WARNING: $1 is not a regular file. Left it in place."
    fi
}

# real_dir PATH: print the real path of the folder PATH, or nothing.
real_dir() {
    (CDPATH= cd -P -- "$1" 2>/dev/null && pwd -P) || true
}

# kept_name ENTRY REAL_SKILLS: print the last part of a manifest entry when
# the helper keeps it. It keeps an entry whose parent resolves to the real
# skills folder and whose last part is not empty, . or ..
kept_name() {
    local parent last="${1##*/}"
    case "$1" in
        */*) parent="${1%/*}"; [ -z "$parent" ] && parent="/" ;;
        *) parent="." ;;
    esac
    case "$last" in ""|.|..) return 0 ;; esac
    if [ "$(real_dir "$parent")" = "$2" ]; then printf '%s' "$last"; fi
    return 0
}

# flags_args DIR: print the setup arguments DIR's flags file holds, or
# nothing when its tool is not one setup accepts. Only the two known flags
# pass, in setup order.
flags_args() {
    local f="$1/$NEW_FLAGS" tool line t args
    if [ ! -f "$f" ] || [ -L "$f" ]; then return 0; fi
    tool="$(sed -n 's/^[[:space:]]*"tool"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$f" | head -n 1)"
    line="$(sed -n 's/^[[:space:]]*"flags"[[:space:]]*:\(.*\)$/\1/p' "$f" | head -n 1)"
    for t in $SETUP_TOOLS; do
        if [ "$t" = "$tool" ]; then
            args="$t"
            case "$line" in *'"--include-full-skill-library"'*) args="$args --include-full-skill-library" ;; esac
            case "$line" in *'"--strict-orchestrator"'*) args="$args --strict-orchestrator" ;; esac
            printf '%s' "$args"
            return 0
        fi
    done
    return 0
}

# rewrite_names FILE: print FILE with the workflow name line, the pack path,
# and the pack-owned variable names rewritten. A name counts only as a whole
# name, and never after secrets. or vars., where it names a consumer secret
# or variable.
rewrite_names() {
    awk -v op="$OLD_PACK/" -v np="$NEW_PACK/" -v old="${OLDU}_" -v new="RAVINTIO_" -v names="$PACK_VARS" \
        -v oldname="$OLD_WF_NAME" -v newname="$NEW_WF_NAME" '
    function isword(c) { return c ~ /[A-Za-z0-9_]/ }
    BEGIN { n = split(names, nm, " ") }
    {
        line = $0
        if (line == oldname || line == oldname "\r") {
            line = newname substr(line, length(oldname) + 1)
        }
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
                ctx = out substr(line, 1, i - 1)
                if ((pre == "" || !isword(pre)) && (post == "" || !isword(post)) && ctx !~ /(secrets|vars)\.$/) {
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
if [ "$IN_GIT" -eq 1 ] && git ls-files -s -- "$OLD_PACK" 2>/dev/null | grep '^160000 ' >/dev/null; then
    stop_at 2 "$OLD_PACK/ is a git submodule. Run git submodule deinit and git rm on it first, then run this helper again."
fi
# The marker clashes, for each tool folder step 5 works in.
for t in $TOOL_DIRS; do
    if marker_skip "$t"; then continue; fi
    if present "$t/$OLD_FLAGS" && present "$t/$NEW_FLAGS"; then
        stop_at 2 "both $t/$OLD_FLAGS and $t/$NEW_FLAGS exist. Keep one of them, then run this helper again."
    fi
    if present "$t/skills/$OLD_MANIFEST" && present "$t/skills/$NEW_MANIFEST"; then
        stop_at 2 "both $t/skills/$OLD_MANIFEST and $t/skills/$NEW_MANIFEST exist. Keep one of them, then run this helper again."
    fi
    scan=""
    if [ -f "$t/skills/$OLD_MANIFEST" ]; then
        scan="$t/skills/$OLD_MANIFEST"
    elif [ -f "$t/skills/$NEW_MANIFEST" ]; then
        scan="$t/skills/$NEW_MANIFEST"
    fi
    if [ -n "$scan" ] && [ -d "$t/skills" ]; then
        rs="$(real_dir "$t/skills")"
        while IFS= read -r entry || [ -n "$entry" ]; do
            entry="${entry%$'\r'}"
            [ -z "$entry" ] && continue
            name="$(kept_name "$entry" "$rs")"
            case "$name" in
                "$OLD"-*)
                    nn="ravintio-${name#"$OLD"-}"
                    if present "$t/skills/$name" && present "$t/skills/$nn"; then
                        stop_at 2 "both $t/skills/$name and $t/skills/$nn exist. Keep one of them, then run this helper again."
                    fi
                    ;;
            esac
        done < "$scan"
    fi
done
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

# Step 5: remove the session marker, then rename the markers in each tool
# folder.
CLAUDE_LINK="$(first_link ".claude")"
if [ -n "$CLAUDE_LINK" ]; then
    echo "WARNING: .claude is a symlink. Skipped the marker under it, so nothing is removed through it."
else
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
for t in $TOOL_DIRS; do
    if [ -L "$t" ]; then
        # The .claude warning above already names a linked .claude.
        if [ "$t" != ".claude" ]; then
            echo "WARNING: $t is a symlink. Skipped the markers in it, so nothing is written through it."
        fi
        continue
    fi
    if [ ! -d "$t" ]; then continue; fi
    skip_link="$(marker_link "$t")"
    if [ -n "$skip_link" ]; then
        echo "WARNING: $skip_link is a symlink. Skipped the markers in $t, so nothing is written through it."
        continue
    fi
    # The flags file keeps its content.
    rename_marker "$t/$OLD_FLAGS" "$t/$NEW_FLAGS"
    if [ ! -d "$t/skills" ]; then continue; fi
    rename_marker "$t/skills/$OLD_MANIFEST" "$t/skills/$NEW_MANIFEST"
    MANIFEST="$t/skills/$NEW_MANIFEST"
    if [ ! -f "$MANIFEST" ]; then continue; fi
    # Keep each entry inside the real skills folder, rename each listed old
    # skill folder, and write each kept entry as the real path.
    rs="$(real_dir "$t/skills")"
    CONTENT=""
    while IFS= read -r entry || [ -n "$entry" ]; do
        entry="${entry%$'\r'}"
        [ -z "$entry" ] && continue
        name="$(kept_name "$entry" "$rs")"
        if [ -z "$name" ]; then
            echo "WARNING: dropped manifest entry $entry"
            continue
        fi
        case "$name" in
            "$OLD"-*)
                nn="ravintio-${name#"$OLD"-}"
                if present "$t/skills/$name"; then
                    move_path "$t/skills/$name" "$t/skills/$nn" 5
                    echo "Step 5: renamed $t/skills/$name to $t/skills/$nn."
                    note_moved "$t/skills/$name to $t/skills/$nn"
                    CHANGED=1
                fi
                name="$nn"
                ;;
        esac
        CONTENT="$CONTENT$rs/$name"$'\n'
    done < "$MANIFEST"
    if ! printf '%s' "$CONTENT" | cmp -s - "$MANIFEST"; then
        # Write to a temporary file in the same folder, then rename it over
        # the target.
        TMP="$(mktemp "$t/skills/$NEW_MANIFEST.XXXXXX")" || stop_at 5 "could not create a temporary file in $t/skills/."
        printf '%s' "$CONTENT" > "$TMP" || stop_at 5 "could not rewrite $MANIFEST. The temporary file $TMP is left for you to check."
        chmod 644 "$TMP"
        mv -f "$TMP" "$MANIFEST" || stop_at 5 "could not replace $MANIFEST. The temporary file $TMP is left for you to check."
        echo "Step 5: rewrote the entries in $MANIFEST."
        CHANGED=1
    fi
done
hook 5

# Step 6: stop git tracking of the old pack, then rename it into the backup.
if [ -d "$OLD_PACK" ]; then
    if tracked "$OLD_PACK"; then
        git rm -r -q --cached -- "$OLD_PACK" >/dev/null 2>&1 || stop_at 6 "could not stop git tracking of $OLD_PACK/."
    fi
    mkdir -p "$BACKUP" || stop_at 6 "could not create $BACKUP/."
    stop_if_present "$BACKUP/$OLD_PACK" 6
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

# Step 7: the next step, with the setup arguments each saved flags file
# holds, or the generic command when none names a tool setup accepts.
SAVED=0
for t in $TOOL_DIRS; do
    if [ -L "$t" ] || [ ! -d "$t" ]; then continue; fi
    args="$(flags_args "$t")"
    if [ -n "$args" ]; then
        echo "Next step: run $NEW_PACK/setup.sh $args, or setup.ps1 with the same arguments, before the next commit."
        SAVED=1
    fi
done
if [ "$SAVED" -eq 0 ]; then
    echo "Next step: run $NEW_PACK/setup.sh claude-code, or setup.ps1, or the tool this project uses, before the next commit."
fi
if [ -d "$BACKUP/$OLD_PACK" ]; then
    echo "The old pack is in $BACKUP/$OLD_PACK/. Delete $BACKUP/ after you check that nothing of yours is in it. git clean -x deletes it too."
fi
hook 7

# Step 8: branch protection.
echo "WARNING: the workflow name is now RAVINTIO Strict Pipeline. The required check validate-branch keeps its name, so a branch protection rule that requires validate-branch needs no change."
hook 8

exit 0
