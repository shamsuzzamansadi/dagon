# Sourced by the check scripts. Gives every Godot process in this run one unique storage directory,
# outside user://, so no check can read or overwrite a player's settings (docs/architecture.md §8).
# Removal is limited to the directory this file created.

test_storage_dir="$(mktemp -d "${TMPDIR:-/tmp}/dagon-test-XXXXXX")" || exit 2

remove_test_storage() {
	case "$test_storage_dir" in
		*/dagon-test-*) rm -rf -- "$test_storage_dir" ;;
	esac
}
trap remove_test_storage EXIT

DAGON_STORAGE_DIR="$test_storage_dir"
if command -v cygpath > /dev/null 2>&1; then
	DAGON_STORAGE_DIR="$(cygpath -m "$test_storage_dir")"
fi
export DAGON_STORAGE_DIR
