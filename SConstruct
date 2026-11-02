#!/usr/bin/env python
# Derived from godot-cpp-template @ d36f9d03e9e0 (Unlicense).
import os
import subprocess
import sys

from methods import print_error

libname = "dagon"
projectdir = "project"

localEnv = Environment(tools=["default"], PLATFORM="")

customs = ["custom.py"]
customs = [os.path.abspath(path) for path in customs]

opts = Variables(customs, ARGUMENTS)
opts.Add(BoolVariable("show_flags", "Print the compiler version and effective flags", False))
opts.Add(BoolVariable("require_msvc", "Fail instead of falling back when Windows builds would not use MSVC", False))
opts.Update(localEnv)

Help(opts.GenerateHelpText(localEnv))

env = localEnv.Clone()

if not (os.path.isdir("godot-cpp") and os.listdir("godot-cpp")):
    print_error("""godot-cpp is not available within this folder, as Git submodules haven't been initialized.
Run the following command to download godot-cpp:

    git submodule update --init --recursive""")
    sys.exit(1)

env = SConscript("godot-cpp/SConstruct", {"api_version": "4.7", "env": env, "customs": customs})

# godot-cpp silently falls back to MinGW when it does not detect MSVC.
if localEnv["require_msvc"] and env["platform"] == "windows" and not env.get("is_msvc", False):
    print_error("require_msvc=yes, but this build would not use MSVC (CXX={}).".format(env.subst("$CXX")))
    sys.exit(1)

# godot-cpp compiles as C++17. Only our own sources use C++20: every other flag
# stays identical because this env is a clone (docs/toolchain.md §2).
own = env.Clone()
own.Replace(CXXFLAGS=[flag for flag in own["CXXFLAGS"] if flag not in ("-std=c++17", "/std:c++17")])
own.Append(CXXFLAGS=["/std:c++20"] if own.get("is_msvc", False) else ["-std=c++20"])
own.Append(CPPPATH=["src/"])

sources = Glob("src/*.cpp") + Glob("src/core/*.cpp")

# .dev doesn't inhibit compatibility, so we don't need to key it.
suffix = own["suffix"].replace(".dev", "").replace(".universal", "")

lib_filename = "{}{}{}{}".format(own.subst("$SHLIBPREFIX"), libname, suffix, own.subst("$SHLIBSUFFIX"))

library = own.SharedLibrary("bin/{}/{}".format(own["platform"], lib_filename), source=sources)

copy = own.Install("{}/bin/{}/".format(projectdir, own["platform"]), library)

Default(library, copy)

if localEnv["show_flags"]:
    print("dagon: target={} platform={} arch={}".format(own["target"], own["platform"], own["arch"]))
    print("dagon: godot-cpp CXXFLAGS={}".format(env.subst("$CXXFLAGS")))
    print("dagon: own CXXFLAGS={}".format(own.subst("$CXXFLAGS")))
    print("dagon: CCFLAGS={}".format(own.subst("$CCFLAGS")))
    print("dagon: CPPDEFINES={}".format(own.subst("$_CPPDEFFLAGS")))
    print("dagon: LINKFLAGS={}".format(own.subst("$LINKFLAGS")))
    version_args = [own.subst("$CXX")] if own.get("is_msvc", False) else [own.subst("$CXX"), "--version"]
    version = subprocess.run(version_args, env=own["ENV"], capture_output=True, text=True, shell=own.get("is_msvc", False))
    print("dagon: compiler: {}".format((version.stderr + version.stdout).strip().splitlines()[0]))

# Native unit tests: plain C++20 with no godot-cpp. Build and run with `scons unit_tests`.
test_env = Environment(tools=["default"])
if localEnv["show_flags"]:
    print("dagon: unit_tests compiler: {}".format(test_env.subst("$CXX")))
if "msvc" in test_env["TOOLS"]:
    test_env.Append(CXXFLAGS=["/std:c++20", "/Zc:__cplusplus", "/EHsc", "/W4", "/WX"])
else:
    test_env.Append(CXXFLAGS=["-std=c++20", "-Wall", "-Wextra", "-Wpedantic", "-Werror"])
test_env.Append(CPPPATH=["src/", "tests/unit/"])
test_env.VariantDir("build/tests/core", "src/core", duplicate=0)
test_env.VariantDir("build/tests/unit", "tests/unit", duplicate=0)
test_program = test_env.Program(
    "build/tests/dagon_tests", Glob("build/tests/core/*.cpp") + Glob("build/tests/unit/*.cpp")
)
unit_tests = test_env.Alias("unit_tests", test_program, '"{}"'.format(test_program[0].abspath))
AlwaysBuild(unit_tests)
