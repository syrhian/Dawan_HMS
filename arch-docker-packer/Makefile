SHELL := /bin/bash

PKR ?= packer
IMAGE ?= hms/arch-devops:latest

.PHONY: init validate build run clean

init:
	$(PKR) init .

validate:
	$(PKR) validate .

build:
	$(PKR) build .

run:
	docker run --rm -it $(IMAGE) zsh

clean:
	# Nothing to clean for docker builder; tags live in Docker cache
	@echo "Clean step not applicable (docker image is cached by Docker)."
