#!/usr/bin/env python3
# Description: Common helper functions

import hashlib
import pathlib
import platform
import shutil
import subprocess


def host_arch_target():
    """
    Converts the host architecture to the first part of a target triple
    :return: Target host
    """
    host_mapping = {
        "armv7l": "arm",
        "ppc64": "powerpc64",
        "ppc64le": "powerpc64le",
        "ppc": "powerpc"
    }
    machine = platform.machine()
    return host_mapping.get(machine, machine)


def target_arch(target):
    """
    Returns the architecture from a target triple
    :param target: Triple to deduce architecture from
    :return: Architecture associated with given triple
    """
    return target.split("-")[0]


def host_is_target(target):
    """
    Checks if the current target triple the same as the host.
    :param target: Triple to match host architecture against
    :return: True if host and target are same, False otherwise
    """
    return host_arch_target() == target_arch(target)

def create_gitignore(folder):
    """
    Create a gitignore that ignores all files in a folder. Some folders are not
    known until the script is run so they can't be added to the root .gitignore
    :param folder: Folder to create the gitignore in
    """
    with folder.joinpath(".gitignore").open("w") as gitignore:
        gitignore.write("*")


def current_binutils():
    """
    Simple getter for current stable binutils release
    :return: The current stable release of binutils
    """
    return "binutils-2.34"


def download_binutils(folder):
    """
    Downloads the latest stable version of binutils
    :param folder: Directory to download binutils to
    """
    binutils = current_binutils()
    binutils_folder = folder.joinpath(binutils)
    if not binutils_folder.is_dir():
        # Remove any previous copies of binutils
        for entity in folder.glob('binutils-*'):
            if entity.is_dir():
                shutil.rmtree(entity.as_posix())
            else:
                entity.unlink()

        # Download the tarball
        binutils_tarball = folder.joinpath(binutils + ".tar.xz")
        subprocess.run([
            "curl", "-LSs", "-o",
            binutils_tarball.as_posix(),
            "https://ftp.gnu.org/gnu/binutils/" + binutils_tarball.name
        ],
                       check=True)
        verify_binutils_checksum(binutils_tarball)
        # Extract the tarball then remove it
        subprocess.run(["tar", "-xJf", binutils_tarball.name],
                       check=True,
                       cwd=folder.as_posix())
        create_gitignore(binutils_folder)
        binutils_tarball.unlink()


def verify_binutils_checksum(file):
    # Check the sha256sum of the downloaded package with a known good one
    # To regenerate the sha256sum, download the .tar.xz and .tar.xz.sig files
    # $ gpg --verify *.tar.xz.sig *.tar.xz
    # $ sha256sum *.tar.xz
    file_hash = hashlib.sha256()
    with file.open("rb") as f:
        while True:
            data = f.read(65536)
            if not data:
                break
            file_hash.update(data)
    good_hash = "f00b0e8803dc9bab1e2165bd568528135be734df3fabf8d0161828cd56028952"
    if file_hash.hexdigest() != good_hash:
        raise RuntimeError("binutils sha256sum does not match known good one!")


def print_header(string):
    """
    Prints a fancy header
    :param string: String to print inside the header
    """
    # Use bold red for the header
    print("\033[01;31m")
    for x in range(0, len(string) + 6):
        print("=", end="")
    print("\n== %s ==" % string)
    for x in range(0, len(string) + 6):
        print("=", end="")
    # \033[0m resets the color back to the user's default
    print("\n\033[0m")
