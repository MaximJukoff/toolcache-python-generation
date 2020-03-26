import distutils.sysconfig
import sysconfig
import sys
import platform
import os

# checking variables
system_name = platform.system()  # Darwin, Linux, Windows
version = sys.version.split(" ")[0]
script_dir_linux = "/opt/hostedtoolcache/Python/" + version + "/x64/lib"
script_dir_macos = "/Users/runner/hostedtoolcache/Python/" + version + "/x64/lib" 
dest_shared = sysconfig.get_config_var('DESTSHARED')
configure_ldflags = sysconfig.get_config_var('CONFIGURE_LDFLAGS')
script_dir_checked = sysconfig.get_config_var('SCRIPTDIR')
have_libreadline = sysconfig.get_config_var("HAVE_LIBREADLINE")
nix_systems = ["Darwin", "Linux"]
# check modules

# if Py_ENABLE_SHARED equals 1, we chekc extensions
if sysconfig.get_config_var('Py_ENABLE_SHARED') == 1:
    # check extension through SHLIB_SUFFIX
    ld_library = sysconfig.get_config_var('LDLIBRARY')
    print("python Py_ENABLE_SHARED = 1")
    if not (ld_library.find(".dylib") != -1 or ld_library.find(".so") != -1):
        print("not valid extension")
        exit(1)
    print("extensions are right")

if system_name == "Linux" and not script_dir_checked == script_dir_linux:
    print("SCRIPTDIR not equal expected: " + script_dir_linux + " real: " + script_dir_checked)
    exit(1)

if system_name == "Darwin" and not script_dir_checked == script_dir_macos:
    print("SCRIPTDIR not equal expected: " + script_dir_macos + " real: " + script_dir_checked)
    exit(1)

if not (system_name == "Linux" and "'-Wl,--rpath=/opt/hostedtoolcache/Python/{0}/x64/lib'".format(
        version) in sysconfig.get_config_var(
    'CONFIGURE_LDFLAGS')):
    print("flag -Wl,--rpath doesn't in CONFIGURE_LDFLAGS")
    print("CONFIGURE_LDFLAGS: " + sysconfig.get_config_var("CONFIGURE_LDFLAGS"))

if not (system_name == "Darwin" and (sysconfig.get_config_var('CONFIGURE_LDFLAGS') or "-L" in sysconfig.get_config_var(
        'CONFIGURE_LDFLAGS'))):
    print("flag -L doesn't in CONFIGURE_LDFLAGS")
    print("CONFIGURE_LDFLAGS: " + sysconfig.get_config_var("CONFIGURE_LDFLAGS"))

if system_name in nix_systems and (version < "3.5" or version >= "3.6"):
    if not ("'--enable-optimizations'" in sysconfig.get_config_var('CONFIG_ARGS').split(" ")):
        print("no '--enable-optimizations' for macos")
        exit(1)

if not have_libreadline == 1:
    exit(1)