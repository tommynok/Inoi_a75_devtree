#!/sbin/sh
#
# Clone the TrustKernel device keys into the recovery-only copies that teed
# runs on: init.tee.rc starts it with
#   --prot /mnt/vendor/persist/t6_rec --prot /mnt/vendor/protect_f/tee_rec
# Without those copies teed comes up with no device key, keymint cannot start
# the operation that unwraps the synthetic password, and a correct PIN is
# rejected - visible only as "Begin Operation failed", which is also what a
# wrong PIN produces.
#
# This overrides the copy in the common tree (TARGET_RECOVERY_DEVICE_DIRS lists
# the device path after the common one, so this file wins). Three differences:
#
#  - the common version runs "rm -rf <dest>/*" before looking at the source, so
#    a source that is not mounted yet leaves the destination empty
#  - it does not check the source exists at all
#  - "cp -rfp" leaves the group as root. Observed on a working device:
#        /mnt/vendor/persist/t6/      drwx------ system system
#        /mnt/vendor/persist/t6_rec/  drwx------ system root
#    teed runs as user system / group system, so that works only because the
#    owner happens to match - by accident rather than by design.
#
# Idempotent: safe to run more than once, and safe to run when a source is
# missing.

sync_keys() {
	src="$1"
	dst="$2"

	[ -d "$src" ] || return 0

	mkdir -p "$dst" || return 0
	cp -af "$src"/* "$dst"/ 2>/dev/null
	chown -R system:system "$dst"
	chmod -R 0700 "$dst"
}

sync_keys /mnt/vendor/persist/t6      /mnt/vendor/persist/t6_rec
sync_keys /mnt/vendor/protect_f/tee   /mnt/vendor/protect_f/tee_rec

exit 0
