.PHONY: test-orchestration test-integration test-unit test-smoke

SMOKE_IMAGE := chezmoi-smoke
SMOKE_SRC   := /home/testuser/.local/share/chezmoi

test-orchestration:
	bash tests/orchestration.sh

test-integration:
	bash tests/integration.sh

test-unit:
	fish -c 'fishtape tests/fish/chezmoi_nudge_test.fish \
	         tests/fish/fisher_chezmoi_test.fish \
	         tests/fish/fisher_cold_install_test.fish \
	         tests/fish/git_extras_test.fish \
	         tests/fish/terminal_theme_test.fish'

test-smoke:
	DOCKER_BUILDKIT=1 docker build --target smoke -t $(SMOKE_IMAGE) .
	docker run --rm $(SMOKE_IMAGE) make -C $(SMOKE_SRC) test-orchestration test-integration
