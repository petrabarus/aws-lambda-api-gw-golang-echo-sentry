all: dist/main

local:
	go build -o dist/local lambda/main.go

dist/main: lambda/main.go
	GOARCH=amd64 GOOS=linux go build -o dist/main lambda/main.go

dist: dist/lambda.zip

dist/lambda.zip: dist/main
	cp -rf lambda dist/ && \
		cp -rf vendor dist/
	cd dist && \
		zip -r lambda.zip main lambda vendor
	mkdir -p deployments/terraform/dist && \
		cp dist/lambda.zip deployments/terraform/dist/lambda.zip

clean:
	rm -rf dist
	rm -rfv deployments/terraform/dist/lambda.zip
