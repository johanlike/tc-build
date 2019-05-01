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


def fetch_binutils(folder, update=True):
    """
    Clones/updates the binutils repo
    :param folder: Directory to download binutils to
    """
    binutils_folder = folder.joinpath("binutils")
    if binutils_folder.is_dir():
        if update:
            print_header("Updating binutils")
            subprocess.run(
                ["git", "-C",
                 binutils_folder.as_posix(), "pull", "--rebase"],
                check=True)
    else:
        print_header("Downloading binutils")
        subprocess.run([
            "git", "clone", "git://sourceware.org/git/binutils-gdb.git",
            binutils_folder.as_posix()
        ],
                       check=True)

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
