all: dist/main

dist/main: lambda/main.go
	GOARCH=amd64 GOOS=linux go build -o dist/main lambda/main.go

dist: dist/lambda.zip

dist/lambda.zip: dist/main
	cp -rf lambda dist/lambda && \
		cp -rf vendor dist/vendor
	cd dist && \
		zip -r lambda.zip main lambda vendor
	mkdir -p deployments/terraform/dist && \
		cp dist/lambda.zip deployments/terraform/dist/lambda.zip

clean:
	rm -rf dist
	rm -rfv deployments/terraform/dist/lambda.zip
