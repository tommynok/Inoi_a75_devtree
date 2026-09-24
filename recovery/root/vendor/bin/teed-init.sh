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
# the device path after the common one, so this file wins). The point of the
# override is the source guard: the common version runs "rm -rf <dest>/*"
# before looking at the source at all, so if /mnt/vendor/persist is not mounted
# yet it wipes working copies and leaves nothing behind.
#
# Ownership is deliberately left alone. init calls this as user system, which
# cannot chown, and it does not need to: stock leaves the copies as
# "system root" and teed reads them fine, because it runs as user system and
# the owner matches. Only the mode matters - mkdir creates 0755, so the chmod
# below is what keeps the keys at 0700.
#
# Idempotent: safe to run more than once, and safe to run when a source is
# missing.

sync_keys() {
	src="$1"
	dst="$2"

	[ -d "$src" ] || return 0

	mkdir -p "$dst" || return 0
	cp -af "$src"/* "$dst"/ 2>/dev/null
	chmod -R 0700 "$dst"
}

sync_keys /mnt/vendor/persist/t6      /mnt/vendor/persist/t6_rec
sync_keys /mnt/vendor/protect_f/tee   /mnt/vendor/protect_f/tee_rec

exit 0
