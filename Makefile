.PHONY: test-unit test test-smoke

FISHTAPE    := fish -c 'fishtape'
SMOKE_IMAGE := chezmoi-smoke

UNIT_TESTS := \
	tests/fish/chezmoi_nudge_test.fish \
	tests/fish/git_extras_test.fish

ALL_TESTS := \
	$(UNIT_TESTS) \
	tests/fish/fisher_chezmoi_test.fish \
	tests/fish/fisher_cold_install_test.fish

test-unit:
	fish -c 'fishtape $(UNIT_TESTS)'

test:
	fish -c 'fishtape $(ALL_TESTS)'

test-smoke:
	DOCKER_BUILDKIT=1 docker build --target package-managers-base -t chezmoi-package-managers-base .
	DOCKER_BUILDKIT=1 docker build -f Dockerfile.smoke -t $(SMOKE_IMAGE) .
	docker run --rm $(SMOKE_IMAGE) fish -c \
	    "jj --version && functions -q fisher && cargo nextest --version && uv tool list | grep -q py-spy"
