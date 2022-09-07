package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	echoadapter "github.com/awslabs/aws-lambda-go-api-proxy/echo"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"

	"github.com/getsentry/sentry-go"
	sentryecho "github.com/getsentry/sentry-go/echo"
)

var echoLambda *echoadapter.EchoLambda

func HandleRequest(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	return echoLambda.ProxyWithContext(ctx, request)
}

func AddRoutes(app *echo.Echo) {
	app.GET("/hello1", func(c echo.Context) error {
		return c.String(http.StatusOK, "Hello, World!")
	})

	app.GET("/error1", func(c echo.Context) error {
		return fmt.Errorf("testing error handling")
	})

	app.GET("/error2", func(c echo.Context) error {
		return echo.NewHTTPError(http.StatusBadRequest, "testing bad request")
	})

	app.GET("/error3", func(c echo.Context) error {
		err := echo.NewHTTPError(http.StatusBadRequest, "testing bad request")
		return err
	})

	app.GET("/error4", func(c echo.Context) error {
		var luckyNumber []int
		return c.String(http.StatusOK, fmt.Sprintf("number: %d", luckyNumber[42]))
	})
}

func customHTTPErrorHandler(app *echo.Echo) echo.HTTPErrorHandler {
	return func(err error, ctx echo.Context) {
		sentry.WithScope(func(scope *sentry.Scope) {
			scope.SetRequest(ctx.Request())
			sentry.CaptureException(err)
		})

		app.DefaultHTTPErrorHandler(err, ctx)
	}
}

func NewServer() *echo.Echo {
	app := echo.New()
	AddRoutes(app)
	app.HTTPErrorHandler = customHTTPErrorHandler(app)
	app.Use(middleware.Logger())
	app.Use(middleware.Recover())
	app.Use(sentryecho.New(sentryecho.Options{
		Repanic: true,
	}))

	return app
}

func InitSentry() {
	dsn := os.Getenv("SENTRY_DSN")
	release := os.Getenv("RELEASE")
	fmt.Printf("Sentry DSN: %s\n", dsn)
	fmt.Printf("Release: %s\n", release)
	err := sentry.Init(sentry.ClientOptions{
		Dsn:              dsn,
		TracesSampleRate: 1.0,
		Release:          "my-project-name@" + release,
	})
	if err != nil {
		fmt.Printf("Sentry initialization failed: %v\n", err)
	}

	defer sentry.Flush(2 * time.Second)
	sentry.CaptureMessage("It works!")
}

func main() {
	InitSentry()

	app := NewServer()

	_, present := os.LookupEnv("IS_LOCAL")
	if present {
		app.Logger.Fatal(app.Start(":8080"))
	} else {
		echoLambda = echoadapter.New(app)
		lambda.Start(HandleRequest)
	}
}
