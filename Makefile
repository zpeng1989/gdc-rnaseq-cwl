VERSION := $(shell date -u +"%Y%m%dT%H%MZ")
REPO = gdc-rnaseq-cwl
BRANCH_NAME?=unknown

GIT_SHORT_HASH:=$(shell git rev-parse --short HEAD)
COMMIT_HASH:=$(shell git rev-parse HEAD)

DOCKER_REPO := quay.io/repository/ncigdc
DOCKER_IMAGE_COMMIT := ${DOCKER_REPO}/${REPO}:${COMMIT_HASH}
DOCKER_IMAGE_LATEST := ${DOCKER_REPO}/${REPO}:latest
DOCKER_IMAGE := ${DOCKER_REPO}/${REPO}:${VERSION}

ENTRY_WF = "./workflows/subworkflows/gdc_rnaseq_main_workflow.cwl"

.PHONY: docker-*
docker-login:
	@echo
	$(shell docker login -u="${SQUAY_USERNAME}" -p="${SQUAY_PASSWORD}" quay.io)

.PHONY: version version-*
version:
	@echo --- VERSION: ${VERSION} ---

version-docker:
	@echo ${DOCKER_IMAGE_COMMIT}
	@echo ${DOCKER_IMAGE}

.PHONY: build build-* clean init init-* lint requirements run version
init: init-pip init-hooks

init-pip:
	@echo
	@echo -- Installing pip packages --
	pip3 install --no-cache-dir cwltool==1.0.20180306163216

init-hooks:
	@echo
	@echo -- Installing Precommit Hooks --
	pre-commit install

init-venv:
	@echo
	PIP_REQUIRE_VIRTUALENV=true pip3 install --upgrade pip-tools

clean:
	rm -rf ./build/
	rm -rf ./dist/
	rm -rf ./*.egg-info/

.PHONY: pack pack-%
pack:
	@python -m cwltool --pack "${ENTRY_WF}"

pack-%:
	@make --quiet -C $* run


run:
	@docker run --rm ${DOCKER_IMAGE_LATEST} pack ENTRY_WF=${ENTRY_WF}

.PHONY: build build-*

build: build-docker build-%

build-docker:
	@echo
	@echo -- Building docker --
	docker build . \
		--file ./Dockerfile \
		-t "${DOCKER_IMAGE_COMMIT}" \
		-t "${DOCKER_IMAGE}" \
		-t "${DOCKER_IMAGE_LATEST}"

build-%:
	@echo
	@echo -- Building docker --
	@make -C $* build-docker WORKFLOW_NAME=$*

.PHONY: test test-*
test: lint test-unit

test-docker:
	@echo
	@echo -- Running Docker Test --
	docker run --rm ${DOCKER_IMAGE_LATEST} test
