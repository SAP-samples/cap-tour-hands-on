# syntax=docker/dockerfile:1

ARG VARIANT="24"
FROM mcr.microsoft.com/devcontainers/javascript-node:${VARIANT}

# Add package info for cf CLI
RUN wget -q -O - https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key \
  | gpg --dearmor -o /usr/share/keyrings/cli.cloudfoundry.org.gpg \
  && echo "deb [signed-by=/usr/share/keyrings/cli.cloudfoundry.org.gpg] https://packages.cloudfoundry.org/debian stable main" \
  | tee /etc/apt/sources.list.d/cloudfoundry-cli.list

# Install some generally useful tools,
# including cf CLI
RUN apt-get update \
  && apt-get -y install --no-install-recommends \
  cf8-cli \
  curl \
  git \
  sqlite3 \
  bat \
  yq

# Install SAP CAP SDK globally and prettier
USER node
RUN npm install -g \
  @sap/cds-dk@9.9 \
  prettier

# Create ~/.local/bin/ (as it's in the PATH) & symlink bat -> batcat
RUN mkdir -p "$HOME/.local/bin/" && ln -s "$(which batcat)" "$HOME/.local/bin/bat"

WORKDIR /home/node
