# Indicates to sub-Makefiles that it was invoked by this one.
export TOP_LEVEL_MAKEFILE_INVOKED := true


# Platform-specific flags; these defaults can be overriden in defs.<platform> files,
# where <platform> is the result of `uname` in bash.
export SHARED_LIB_EXT := so

# Submodules.
POLYGLOT := lib/polyglot/
JAVACPP_PRESETS := lib/javacpp-presets/
SUBMODULES := $(addsuffix .git,$(POLYGLOT) $(JAVACPP_PRESETS))

# JLang
export PLC := $(realpath bin/jlangc)

# Hack to allow dependency on PolyLLVM source.
export PLC_SRC := $(realpath $(shell find compiler/src -name "*.java"))

# System JDK.
export JAVAC := javac
export JNI_INCLUDES := \
	-I"$(JAVA_HOME)/include" \
	-I"$(JAVA_HOME)/include/darwin" \
	-I"$(JAVA_HOME)/include/linux"
export JDK_LIB_PATH := $(JAVA_HOME)/jre/lib

JDK ?= jdk
export JDK := $(realpath $(JDK))
export JDK_CLASSES := $(JDK)/out/classes

# Runtime.
export RUNTIME := $(realpath runtime)
export RUNTIME_CLASSES := $(RUNTIME)/out/classes

# Clang.
ifndef CLANG_VERSION
export CLANG_VERSION := 
else
export CLANG_VERSION := -$(CLANG_VERSION)
endif

export CLANG := clang++$(CLANG_VERSION)
export LLC := llc$(CLANG_VERSION)
export SHARED_LIB_FLAGS := -g -lgc -shared -rdynamic

# JDK lib.
export LIBJDK = $(JDK)/out/libjdk.$(SHARED_LIB_EXT)
export LIBJDK_FLAGS = $(SHARED_LIB_FLAGS) -Wl,-rpath,$(RUNTIME)/out

# Runtime lib.
export LIBJVM = $(RUNTIME)/out/libjvm.$(SHARED_LIB_EXT)
export LIBJVM_FLAGS = $(SHARED_LIB_FLAGS)

# Test Dir.
export TESTDIR := $(realpath tests/isolated)

# Example Application Dir.
export EXAMPLEDIR := $(realpath examples)
# Platform-specific overrides.
sinclude defs.$(shell uname)

all: setup compiler runtime jdk

setup:
	@echo "--- Checking setup ---"
	@./bin/check-setup.sh

# Compiler.f
compiler: polyglot
	@echo "--- Building compiler ---"
	@ant -S
	@echo

runtime: compiler jdk-classes
	@echo "--- Building runtime ---"
	@$(MAKE) -C $(RUNTIME)
	@echo

jdk-classes:
	@echo "--- Building $(notdir $(JDK)) classes ---"
	@$(MAKE) -C $(JDK) classes
	@echo

jdk: compiler runtime
	@echo "--- Building $(notdir $(JDK)) ---"
	@$(MAKE) -C $(JDK)
	@echo

polyglot: | $(SUBMODULES)
	@echo "--- Building Polyglot ---"
	@cd $(POLYGLOT); ant -S jar
	@echo

$(SUBMODULES):
	git submodule update --init

tests: setup compiler runtime jdk
	@echo "--- Running Test Suite ---"
	@$(MAKE) -s -C $(TESTDIR)
	@echo

cup: setup compiler runtime jdk
	@echo "--- Building the CUP Parser Generator ---"
	@$(MAKE) -s -C $(EXAMPLEDIR)/cup
	@echo
clean:
	@echo "Cleaning compiler, runtime, and jdk"
	@ant -q -S clean
	@$(MAKE) -s -C $(RUNTIME) clean
	@$(MAKE) -s -C $(JDK) clean
	@$(MAKE) -s -C $(TESTDIR) clean
	@$(MAKE) -s -C $(EXAMPLEDIR)/cup clean
clean-test:
	@echo "Cleaning compiler, runtime, and tests"
	@ant -q -S clean
	@$(MAKE) -s -C $(RUNTIME) clean
	@$(MAKE) -s -C $(TESTDIR) clean

.PHONY: compiler runtime jdk-classes jdk clean-test