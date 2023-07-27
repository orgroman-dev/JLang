#!/bin/bash

if ! which ant &>/dev/null
then
    echo "- ant not found. Is ANT installed?"
    exit 1
else
    echo "+ ant found"
fi

if ! which java &>/dev/null
then
    echo "- java not found. Is Java installed?"
    exit 1
else
    echo "+ java found"
fi

if ! which javac &>/dev/null
then
    echo "- javac not found. Is JDK installed?"
    exit 1
else
    echo "+ JDK found"
fi

if git lfs install 2>&1 >/dev/null
then
  echo "+ git lfs installed"
else
  echo "- git lfs is not installed. See https://git-lfs.github.com/"
  exit 1
fi

llvm_version="`$LLC -version | egrep LLVM.version | awk '{print $3}'`"
if [[ -z "$llvm_version" ]]
then
  echo "- llc not found. Is LLVM installed and llc in the current path?"
else
  echo "+ LLVM version is: $llvm_version"
fi

clang_version="`$CLANG --version | egrep clang.version | awk '{print $3}' | awk -F'-' '{print $1}'`"

if [[ "$llvm_version" != "$clang_version" ]]
then
  echo "- llc and clang versions do not match: $llvm_version vs $clang_version"
  exit 1
else
  echo "+ llc and clang versions match: $llvm_version"
fi

if [[ $(uname) == "Linux" ]]
then
    LGC_CHECK_CMD="ld -lgc &>/dev/null"
elif [[ $(uname) == "Darwin" ]]
then
    LGC_CHECK_CMD="! ld -lgc 2>&1 >/dev/null | grep -q \"library not found\""
else
    echo "- The operating system $(uname) is not supported."
    exit 1
fi

if ! eval $LGC_CHECK_CMD
then
    echo "- The Boehm-Demers-Weiser garbage collector (libgc) is not installed as a shared library"
    exit 1
else
    echo "+ Found libgc shared library"
fi

echo "Setup looks good"
exit 0