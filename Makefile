# PKGS returns all Go packages in the Gidari code base.
PKGS = $(or $(PKG),$(shell env GO111MODULE=on $(GC) list ./...))

# TESTPKGS returns all Go packages int the Gidari code base that contain "*_test.go" files.
TESTPKGS = $(shell env GO111MODULE=on $(GC) list -f \
            '{{ if or .TestGoFiles .XTestGoFiles }}{{ .ImportPath }}{{ end }}' \
            $(PKGS))

# GC is the go compiler.
GC = go

export GO111MODULE=on

default:
	chmod +rwx scripts/*.sh
	$(GC) build -o gidari-cli cmd/gidari/cmd.go

# containers build the docker containers for performing integration tests.
.PHONY: containers
containers:
	scripts/build-storage.sh

# proto is a phony target that will generate the protobuf files.
.PHONY: proto
proto:
	protoc --proto_path=internal/proto --go_out=internal/proto internal/proto/db.proto

# test runs all of the application tests locally.
.PHONY: tests
tests:
	$(GC) clean -testcache

	# Run each test 3 times to minimalize flakey tests.
	@$(foreach dir,$(TESTPKGS), $(GC) test $(dir) -v -count=3;)

# ci are the integration tests in CI/CD.
.PHONY: e2e
e2e:
	$(GC) clean -testcache
	./scripts/run-e2e-tests.sh

# lint runs the linter.
.PHONY: lint
lint:
	scripts/lint.sh

# fmt runs the formatter.
.PHONY: fmt
fmt:
	./scripts/fmt.sh

# add-license adds the license to all the top of all the .go files.
.PHONY: add-license
add-license:
	./scripts/add-license.sh
