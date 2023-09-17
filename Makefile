docker-image:
ifeq ($(shell uname -m),arm64)  # apple silicon
	docker buildx build --platform=linux/amd64 -t test .
else
	docker build -t test .
endif

