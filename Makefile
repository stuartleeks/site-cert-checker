help: ## show this help
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%s\033[0m|%s\n", $$1, $$2}' \
	| column -t -s '|'


trigger-function: ## manually trigger the function locally
	curl -H "Content-Type:application/json" -d "{}" http://localhost:7071/admin/functions/CheckSites

run: ## run the function locally
	cd functions && yarn run start

bicep-build: 
	bicep build deploy/src/main.bicep --outdir deploy/out