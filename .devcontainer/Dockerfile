# [Choice] OCaml version: 3.14, 3.13, 3.12, 3.11
ARG OCAML_VERSION=4.13
FROM ocaml/opam:debian-ocaml-${OCAML_VERSION}

USER root
# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && \
  apt install -y \
  libgmp-dev \
  pkg-config \
  zlib1g-dev \
  && \
  rm -rf /var/lib/apt/lists/*

USER opam

RUN opam update && \
  opam install \
  ocaml-lsp-server \
  odoc \
  ocamlformat \
  utop \
  core \
  cryptokit

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog

# ENV PATH=/home/opam/.opam/${OCAML_VERSION}/bin:$PATH

# ** [Optional] Uncomment this section to install additional packages. **
# RUN apk update \
#     && apk add --no-cache <your-package-list-here>
