# n8n with a node security overlay: if a newer node patch of the same major is
# out than the one upstream ships, it replaces upstream's binary (see node-overlay.sh).
ARG N8N_VERSION
ARG NODE_VERSION
FROM docker.io/library/node:${NODE_VERSION}-alpine AS node

FROM docker.io/n8nio/n8n:${N8N_VERSION}
USER root
COPY --from=node /usr/local/bin/node /tmp/node-overlay/node
COPY --from=node /usr/lib/libatomic.so.1 /tmp/node-overlay/libatomic.so.1
COPY node-overlay.sh /tmp/node-overlay.sh
RUN sh /tmp/node-overlay.sh && rm -rf /tmp/node-overlay /tmp/node-overlay.sh
USER node
