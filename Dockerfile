FROM node:18-bullseye-slim

ENV WORK /opt/map-matcher
ENV NODE_ENV production

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    wget ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p ${WORK}
WORKDIR ${WORK}

# Install app dependencies
COPY package.json yarn.lock ${WORK}
RUN yarn && yarn cache clean

COPY . ${WORK}
# init data folder
RUN mkdir -p ${WORK}/data

ENV PORT 3000
EXPOSE ${PORT}

CMD [ "yarn", "start:production" ]
