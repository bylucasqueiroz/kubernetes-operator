APP_NAME=k8s-operator
IMAGE=$(APP_NAME):latest
NAMESPACE=default

.PHONY: help build docker-env deploy delete logs restart test clean

help:
	@echo "Available commands:"
	@echo "  make docker-env   -> Point shell to minikube docker"
	@echo "  make build        -> Build docker image"
	@echo "  make deploy       -> Apply Kubernetes manifests"
	@echo "  make delete       -> Delete Kubernetes resources"
	@echo "  make restart      -> Restart deployment"
	@echo "  make logs         -> Tail logs"
	@echo "  make test         -> Call update endpoint"
	@echo "  make clean        -> Delete image from local docker"

# Use docker from minikube
docker-env:
	eval $$(minikube docker-env)

# Build docker image inside minikube
build:
	eval $$(minikube docker-env) && \
	docker build -t $(IMAGE) .

deploy:
	helm upgrade --install k8s-operator ./manifests/helm/k8s-operator

delete:
	helm uninstall k8s-operator

restart:
	kubectl rollout restart deployment $(APP_NAME) -n $(NAMESPACE)

logs:
	kubectl logs -l app=$(APP_NAME) -n $(NAMESPACE) -f

test:
	curl "http://$$(minikube ip):30007/update?namespace=argocd&name=example-appset"

clean:
	docker rmi $(IMAGE) || true