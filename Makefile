export GUEST_MODULE_PREFIX:=$(abspath .)

.PHONY: build-dev
build-dev:
	@echo Creating a DEBUG build
	cargo build --workspace
	make -C lucet-builtins

.PHONY: build
build:
	@echo Creating a RELEASE build
	cargo build --workspace --release --bins --lib
	make -C lucet-builtins

.PHONY: install
install: build
	@helpers/install.sh

.PHONY: install-dev
install-dev: build-dev
	@helpers/install.sh --unoptimized

.PHONY: test
test: indent-check test-packages

.PHONY: test-packages
test-packages:
	cargo test --no-fail-fast \
            -p lucet-runtime-internals \
            -p lucet-runtime \
            -p lucet-module \
            -p lucetc \
            -p lucet-wasi-sdk \
            -p lucet-wasi \
            -p lucet-wasi-fuzz \
            -p lucet-validate \
            -p lucet-wiggle

.PHONY: test-full
test-full: indent-check audit book test-except-fuzz test-fuzz

.PHONY: test-except-fuzz
test-except-fuzz: test-packages
	# check but do *not* build or run these packages to mitigate bitrot
	cargo check -p lucet-spectest -p lucet-runtime-example
	# run the benchmarks in debug mode
	cargo test --benches -p lucet-benchmarks -- --test
	helpers/lucet-toolchain-tests/signature.sh
	cargo build -p lucet-objdump
	helpers/lucet-toolchain-tests/objdump.sh

# run a single seed through the fuzzer to stave off bitrot
.PHONY: test-fuzz
test-fuzz:
	cargo run -p lucet-wasi-fuzz -- test-seed 410757864950

FUZZ_NUM_TESTS?=1000
.PHONY: fuzz
fuzz:
	cargo run --release -p lucet-wasi-fuzz -- fuzz --num-tests=$(FUZZ_NUM_TESTS)

.PHONY: book
book:
	mdbook build docs

.PHONY: bench
bench:
	cargo bench -p lucet-benchmarks
	make -C benchmarks/shootout clean
	make -C benchmarks/shootout bench

.PHONY: audit
audit:
	cargo audit

.PHONY: clean
clean:
	make -C benchmarks/shootout clean
	make -C lucet-builtins clean
	cargo clean

.PHONY: indent
indent:
	helpers/indent.sh

.PHONY: indent-check
indent-check:
	helpers/indent.sh check

.PHONY: package
package:
	cargo deb -p lucet-validate
	cargo deb -p lucetc

.PHONY: watch
watch:
	cargo watch --exec "test \
            -p lucet-runtime-internals \
            -p lucet-runtime \
            -p lucet-module \
            -p lucetc \
            -p lucet-wasi-sdk \
            -p lucet-wasi \
            -p lucet-benchmarks \
            -p lucet-validate"
