# Shared by install.sh, reinstall.sh, build-deb.sh and build-in-container.sh.
# PKGBUILD and the RPM spec carry an inline copy of the same logic (they cannot
# source repo helpers from the fork checkout) — keep in sync.
#
# Apply patches/cs9711-scan-cancel-cleanup.patch — upstream commit 256ad3d
# ("Fix CS9711 scan cancellation cleanup"), so far only on archeYR's
# cs9711-rebase-testing branch, not on the default cs9711-rebase we build.
# Idempotent: cs9711_scan_error_action() is the done-marker, so a re-run
# (reinstall.sh on an already-patched tree) is a no-op, and so is a tree where
# upstream has merged the fix into the default branch.
# Deliberately non-fatal: the driver works without this fix, so if a future
# upstream change makes the patch stop applying we build unpatched and warn
# instead of aborting the install. git apply is atomic — no half-applied tree.
#
# Usage: apply_scan_cancel_patch <driver-dir> <absolute-patch-path>
# Sets SCAN_CANCEL_STATUS to applied | present | skipped. Returns 1 only for
# skipped, so callers under set -e must test it with if.
apply_scan_cancel_patch() {
    local dir="$1" patch="$2"
    local src="$dir/libfprint/drivers/cs9711/cs9711.c"
    SCAN_CANCEL_STATUS=skipped
    [ -f "$src" ] && [ -f "$patch" ] || return 1
    if grep -q 'cs9711_scan_error_action' "$src"; then
        SCAN_CANCEL_STATUS=present
        return 0
    fi
    if (cd "$dir" && git apply --check "$patch" 2>/dev/null && git apply "$patch"); then
        SCAN_CANCEL_STATUS=applied
        return 0
    fi
    return 1
}
