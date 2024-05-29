package main

import (
	"fmt"
	"net/http"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

// The input type and the output type are defined by the API Gateway.
func handleRequest(req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	fmt.Printf("Body, %s!\n", req.Body)
	name, ok := req.QueryStringParameters["name"]
	if !ok {
		res := events.APIGatewayProxyResponse{
			StatusCode: http.StatusBadRequest,
		}
		return res, nil
	}

	res := events.APIGatewayProxyResponse{
		StatusCode: http.StatusOK,
		Headers:    map[string]string{"Content-Type": "text/plain; charset=utf-8"},
		Body:       fmt.Sprintf("Hello, %s!\n", name),
	}
	return res, nil
}

func main() {
	lambda.Start(handleRequest)
}
