# standardnotes-app-images
Provide custom build of standardnotes client side image/binaries.

1. Docker image for standardnotes web
2. Android APK for standardnotes mobile
3. [TODO] ASAR file for Desktop version

Will not provide iOS related binaries.

**Note: Although they claim [this](https://github.com/standardnotes/self-hosted/issues/116)(and lock the thread LOL) and [this](https://standardnotes.com/blog/making-self-hosting-easy-for-all) (Yes, you're secure, but what if you go out of business. Meme here: there's no cloud , just SOMEBODY ELSE'S COMPUTER ), Those who self-hosting client-side part(like web) ought to be ABLE TO USE the full range of client-side features. So I modified the javascript part (isThirdPartyHostUsed function) to bypass client-side check (Available after 3.147.0). Thank you standardnotes BUT F\*\*K YOU.**


## Readme for android apk

I modified `isThirdPartyHostUsed` function and built apk with a [public shared](https://ask.dcloud.net.cn/article/36522) [android certificate](https://download.dcloud.net.cn/keystore/Test.keystore) (alias: "android" key-password: 123456 keystore-password: 123456) (so you can build and update your own apk seamlessly). 

And also since it is a public shared certificate, use it under your own risk (for example: attacked by sharedUserId mechanism).

The APK's versionCode is based on unixtimestamp / 60, basically you'll not encounter downgrade issue.

Adjust minsdk version from 28 to 21 for old devices.

## Readme for web image

**Note: Since there's no CSP header in HTTP response of this image, use it under your own risk.**

### Why

Since standardnotes use static-web hosting on S3 and Cloudfront instead of using `standardnotes/web` docker image (Ruby-On-Rails based web server), so there's no `standardnotes/web` docker image anymore.

However the static web do not support configure sync server url and other settings. For self-hosters, we need a docker image which is configurable.


### Build

**In this repo, The workflow of build-and-push task is manually triggered with user inputed standardnotes/web's version and weekly based schedule triggered with automatically fetching the latest standardnotes/web's version.**

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

#### FAQ:

1. Javascript Heap Overflow

    add `ENV NODE_OPTIONS=--max_old_space_size=<SMALLER_MEMSIZE_IN_MB>` before `RUN yarn ...` in Dockerfile

2. Buildkit not supported/ Heredoc syntax not supported

    create a `40-standardnotes-app-envsubst.sh` which content is the string between two `EOF`s , then `chmod +x 40-standardnotes-app-envsubst.sh` and then replace `COPY <<EOF ... EOF` to  `COPY 40-standardnotes-app-envsubst.sh /docker-entrypoint.d/` and delete `RUN  chmod +x ...` and delete the first line  `# syntax=docker/dockerfile:1.4` , then `docker build --build-arg STANDARDNOTES_WEB_VERSION=3.x.x -f ./Dockerfile .`



### Usage

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
