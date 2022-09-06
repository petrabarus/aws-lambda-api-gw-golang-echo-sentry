package main

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func HandleRequest(ctx context.Context, request events.APIGatewayProxyRequest) (string, error) {
	jsonObj, _ := json.Marshal(request)
	fmt.Println(string(jsonObj))
	return "Hello World!", nil
}

func main() {
	lambda.Start(HandleRequest)
}
