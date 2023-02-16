# syntax=docker/dockerfile:1.4
## Above line is used to support heredoc feature under buildkit
## Build with  DOCKER_BUILDKIT=1 docker build --build-arg STANDARDNOTES_WEB_VERSION=3.x.x
FROM alpine:latest as builder
ARG STANDARDNOTES_WEB_VERSION
# since alpine(3.17) update nodejs version (v18.12) , but node-sass (old version 6.0.1) do not have binary release which matching that NODE_MODULE_VERSION
# so it need to be built from scratch which requiring Python make and g++ OR just old alpine like 3.16
RUN apk --no-cache add git yarn python3 make g++ && git clone https://github.com/standardnotes/app -b @standardnotes/web@${STANDARDNOTES_WEB_VERSION} --depth=1

WORKDIR /app
## Uncomment following line if encounting Javascript Heap Overflow
#ENV NODE_OPTIONS=--max_old_space_size=<SMALLER_MEMSIZE_IN_MB>
RUN  sed -i '/isThirdPartyHostUsed/a \ \ \ \ return false;' packages/snjs/lib/Services/Api/ApiService.ts && \
yarn install --immutable && yarn build:web && \
sed -i 's|link rel="canonical" href="https://app.standardnotes.com"|link rel="canonical" href="$APP_HOST"|' packages/web/dist/index.html && \
sed -i 's|window.defaultSyncServer = "https://api.standardnotes.com";|window.defaultSyncServer = "$DEFAULT_SYNC_SERVER";|' packages/web/dist/index.html && \
sed -i 's|window.defaultFilesHost = "https://files.standardnotes.com";|window.defaultFilesHost = "$DEFAULT_FILES_HOST";|' packages/web/dist/index.html && \
sed -i 's|window.enabledUnfinishedFeatures = false;|window.enabledUnfinishedFeatures = "$ENABLE_UNFINISHED_FEATURES" === 'true';|' packages/web/dist/index.html && \
sed -i 's|window.websocketUrl = "wss://sockets.standardnotes.com";|window.websocketUrl = "$WEBSOCKET_URL";|' packages/web/dist/index.html && \
sed -i 's|window.purchaseUrl = "https://standardnotes.com/purchase";|window.purchaseUrl = "$PURCHASE_URL";|' packages/web/dist/index.html && \
sed -i 's|window.plansUrl = "https://standardnotes.com/plans";|window.plansUrl = "$PLANS_URL";|' packages/web/dist/index.html && \
sed -i 's|window.dashboardUrl = "https://standardnotes.com/dashboard";|window.dashboardUrl = "$DASHBOARD_URL";|' packages/web/dist/index.html && \
mv packages/web/dist/index.html  packages/web/dist/index.html.template && \
sed -i 's|https://app.standardnotes.com|$APP_HOST|' packages/web/dist/manifest.webmanifest && \
mv packages/web/dist/manifest.webmanifest packages/web/dist/manifest.webmanifest.template

FROM nginx:alpine
COPY --from=builder /app/packages/web/dist  /usr/share/nginx/html
## If you encouting issue with Heredoc , you can create a 40-standardnotes-app-envsubst.sh and chmod +x 40-standardnotes-app-envsubst.sh and then COPY 40-standardnotes-app-envsubst.sh /docker-entrypoint.d/
## To avoid keep restaring when restart this container. do envsubst only when template file exists.
COPY <<EOF   /docker-entrypoint.d/40-standardnotes-app-envsubst.sh
( [[ -f /usr/share/nginx/html/index.html.template ]] && envsubst '\$APP_HOST,\$DEFAULT_SYNC_SERVER,\$DEFAULT_FILES_HOST,\$ENABLE_UNFINISHED_FEATURES,\$WEBSOCKET_URL,\$PURCHASE_URL,\$PLANS_URL,\$DASHBOARD_URL' < /usr/share/nginx/html/index.html.template > /usr/share/nginx/html/index.html && rm /usr/share/nginx/html/index.html.template ); ( [[ -f /usr/share/nginx/html/manifest.webmanifest.template ]] &&  envsubst '\$APP_HOST' < /usr/share/nginx/html/manifest.webmanifest.template > /usr/share/nginx/html/manifest.webmanifest && rm /usr/share/nginx/html/manifest.webmanifest.template ); exit 0
EOF
RUN chmod +x /docker-entrypoint.d/40-standardnotes-app-envsubst.sh
