# builder stage
FROM golang:1.23.0 AS base 

WORKDIR /app 

# copy requirements file
COPY go.mod /app    

RUN go mod download 

COPY . .

RUN go build -o main  . 

# production stage using distroless image
FROM gcr.io/distroless/base

# copy executable file from build stage
COPY --from=base /app/main .

# copy static files that contain the codebase
COPY --from=base /app/static ./static

EXPOSE 8080

CMD ["./main"]