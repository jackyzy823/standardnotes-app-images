# standardnotes-web-image
Provide standardnotes/web docker image

**In this repo, The workflow of build-and-push task is manually triggered with user inputed standardnotes/web's version.**

## Build

You can also build it yourself with Buildkit.

Using (with docker buildx plugin)
`
docker buildx build --build-arg STANDARDNOTES_WEB_VERSION=3.x.x -f ./Dockerfile .
` 
or
`
 DOCKER_BUILDKIT=1 docker build --build-arg STANDARDNOTES_WEB_VERSION=3.x.x -f ./Dockerfile .
`

Docker Build Arguments:

`STANDARDNOTES_WEB_VERSION`: the standardnote/web [tag](https://github.com/standardnotes/app/tags) version (example @standardnotes/web@3.44.3 -> 3.44.3)

### FAQ:

1. Javascript Heap Overflow

    add `ENV NODE_OPTIONS=--max_old_space_size=<SMALLER_MEMSIZE_IN_MB>` before `RUN yarn ...` in Dockerfile

2. Buildkit not supported/ Heredoc syntax not supported

    create a `40-standardnotes-app-envsubst.sh` which content is the string between `EOF` and `chmod +x 40-standardnotes-app-envsubst.sh` and then replace `COPY <<EOF ... EOF` to  `COPY 40-standardnotes-app-envsubst.sh /docker-entrypoint.d/` and delete `RUN  chmod +x ...` and delete the first line  `# syntax=docker/dockerfile:1.4` , then `docker build --build-arg STANDARDNOTES_WEB_VERSION=3.x.x -f ./Dockerfile .`



## Usage

Runtime environments (same from .env.sample):

```
$APP_HOST
$DEFAULT_SYNC_SERVER
$DEFAULT_FILES_HOST
$ENABLE_UNFINISHED_FEATURES
$WEBSOCKET_URL
$PURCHASE_URL
$PLANS_URL
$DASHBOARD_URL
```

Since this image is based on nginx:alpine, so all nginx's environments and configurations are supported.

Example:

`docker run -p 8080:80 -d -e APP_HOST=https://example.com -e DEFAULT_SYNC_SERVER=https://app.example.com docker pull ghcr.io/jackyzy823/standardnotes-web:3.x.x`
