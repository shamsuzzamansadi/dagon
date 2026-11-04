#!/usr/bin/env sh
# Publishes CI evidence as annotations. Usage: tools/ci_annotate.sh <build|tests|entry> <platform> [job name]
# Reporting only: always exits 0, so it cannot mask or cause a job failure.
group="$1"
platform="$2"
job="${3:-$2}"

notice() { # notice <title> <file> <pattern>
	line="$(grep -hE "$3" "$2" 2> /dev/null | head -n 1 | tr -d '\r')"
	echo "::notice title=$job $1::${line:-missing}"
}

exit_of() { # exit_of <title> <file>
	echo "::notice title=$job $1::exit=$(cat "$2" 2> /dev/null | tr -d '\r' || true)"
}

case "$group" in
	build)
		notice compiler build/logs/build-debug.log '^dagon: compiler:'
		notice unit-tests-compiler build/logs/build-debug.log '^dagon: unit_tests compiler:'
		notice own-cxxflags-debug build/logs/build-debug.log '^dagon: own CXXFLAGS'
		notice godot-cpp-cxxflags-debug build/logs/build-debug.log '^dagon: godot-cpp CXXFLAGS'
		notice ccflags-debug build/logs/build-debug.log '^dagon: CCFLAGS'
		notice ccflags-release build/logs/build-release.log '^dagon: CCFLAGS'
		notice defines-debug build/logs/build-debug.log '^dagon: CPPDEFINES'
		notice defines-release build/logs/build-release.log '^dagon: CPPDEFINES'
		notice linkflags-release build/logs/build-release.log '^dagon: LINKFLAGS'
		notice unit-tests build/logs/unit-tests.log 'test cases:'
		;;
	tests)
		exit_of import build/logs/godot/import.exit
		notice extension-load-debug-library build/logs/godot/check_classes.stdout '^CHECK_CLASSES'
		exit_of extension-load-exit build/logs/godot/check_classes.exit
		notice integration build/logs/godot/integration.stdout '^RESULT'
		exit_of integration-exit build/logs/godot/integration.exit
		notice smoke-debug-library build/logs/godot/smoke.stdout 'dagon: extension initialized'
		exit_of smoke-exit build/logs/godot/smoke.exit
		notice exported-release-library "build/logs/export/run-$platform.all" 'dagon: extension initialized'
		exit_of exported-run-exit "build/logs/export/run-$platform.exit"
		notice first-error build/logs/godot/integration.errors '.'
		;;
	entry)
		notice check-art build/logs/check-art.log '^CHECK_ART'
		notice smoke-entry-scene build/logs/godot/smoke.stdout "Completed load for: 'res://scenes/ui/title.tscn'"
		notice smoke-game-prompt build/logs/godot/smoke_game.stdout "dagon: prompt:"
		notice smoke-greybox-scene build/logs/godot/smoke_greybox.stdout "Completed load for: 'res://scenes/level/level.tscn'"
		exit_of smoke-greybox-exit build/logs/godot/smoke_greybox.exit
		notice exported-entry-scene "build/logs/export/run-$platform.all" "Completed load for: 'res://scenes/ui/title.tscn'"
		notice exported-new-game-prompt "build/logs/export/run-$platform-new-game.all" "dagon: prompt:"
		notice exported-continue "build/logs/export/run-$platform-continue.all" "dagon: session start"
		notice exported-pack-integration "build/logs/export/integration-$platform-pack.stdout" '^RESULT'
		exit_of exported-pack-integration-exit "build/logs/export/integration-$platform-pack.exit"
		notice exported-pack-first-failed-test "build/logs/export/integration-$platform-pack.stdout" '^FAIL'
		notice user-dir-probe build/logs/user-dir-probe.log '^USER_DIR_PROBE'
		notice exported-route build/logs/route.log '^ROUTE_RESULT'
		notice exported-route-first-failure build/logs/route.log 'FAILED'
		notice first-failed-test build/logs/godot/integration.stdout '^FAIL'
		notice first-failure-detail build/logs/godot/integration.stdout '^     '
		;;
esac
exit 0
