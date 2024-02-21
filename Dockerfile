FROM nginx:1.25.4

ENV DEBIAN_FRONTEND=noninteractive

# install tc (from iproute2)
RUN apt-get update -qq \
  && apt-get install -y iproute2 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
