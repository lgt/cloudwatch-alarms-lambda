ARG BUILD_MODE='production'

FROM node:20.14.0-alpine as base

WORKDIR /opt/app
COPY package*.json /opt/app/

ENV TZ=Europe/Berlin


FROM base as base-with-dev-dependencies

# ARG GITHUB_NPM_TOKEN

# RUN npm set @urbanmedia:registry=https://npm.pkg.github.com/urbanmedia
# ## Ensure npmjs.org registry is the default registry
# RUN echo "registry=https://registry.npmjs.org/" >> ~/.npmrc
# RUN echo "//npm.pkg.github.com/:_authToken=\"${GITHUB_NPM_TOKEN}\"" >> ~/.npmrc

ENV NODE_ENV=development
RUN if [ -f package-lock.json ] ; then npm ci ; else npm install ; fi


FROM base-with-dev-dependencies as builder-production

COPY ./ /opt/app/

ENV NODE_ENV=production
RUN npm run build


FROM base-with-dev-dependencies as base-with-prod-dependencies

# remove development dependencies
RUN npm prune --production


FROM base as runtime-base-production

COPY --from=base-with-prod-dependencies /opt/app/node_modules node_modules


FROM base-with-dev-dependencies as runtime-base-development


FROM runtime-base-${BUILD_MODE} as default

COPY --from=builder-production /opt/app/build /opt/app/build

ENV NODE_ENV=${BUILD_MODE}

ARG LOG_LEVEL

ENV LOG_LEVEL=${LOG_LEVEL} 



FROM node:20.14.0 as lambda-builder

WORKDIR /opt/app

# Install build dependencies
RUN apt-get update && \
    apt-get install -y \
    g++ \
    make \
    cmake \
    unzip \
    libcurl4-openssl-dev

# Install AWS Lambda RIE
RUN mkdir -p /aws-lambda && \
    curl -Lo /aws-lambda/aws-lambda-rie https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie && \
    chmod +x /aws-lambda/aws-lambda-rie

COPY --from=base-with-prod-dependencies /opt/app/node_modules node_modules

# Install the runtime interface client
RUN npm install aws-lambda-ric

FROM default

COPY --from=lambda-builder /opt/app/node_modules node_modules
COPY --from=lambda-builder /aws-lambda/aws-lambda-rie /aws-lambda/aws-lambda-rie

# Required for Node runtimes which use npm@8.6.0+ because
# by default npm writes logs under /home/.npm and Lambda fs is read-only
ENV NPM_CONFIG_CACHE=/tmp/.npm

# Set runtime interface client as default command for the container runtime
ENTRYPOINT ["/aws-lambda/aws-lambda-rie"]
# Pass the name of the function handler as an argument to the runtime
CMD ["build/lambda.handler"]