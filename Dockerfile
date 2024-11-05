FROM ruby:2.7
# Add Jekyll dependencies to Alpine

# Update the Ruby bundler and install Jekyll

COPY . /site

WORKDIR /site

RUN make bundle
RUN make serve-public
