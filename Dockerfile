FROM alpine:latest

LABEL maintainer="Florian Tieben <ftiebe@gmail.com>"
LABEL version="4.8.3"
LABEL CONDA_VERSION="4.8.3"
LABEL PYTHON_VERSION="3.7"
LABEL GLIBC_VERSION="2.32-r0"

# Inspired by :
# * https://github.com/datarevenue-berlin/alpine-miniconda
# * https://github.com/jupyter/docker-stacks
# * https://github.com/CognitiveScale/alpine-miniconda
# * https://github.com/show0k/alpine-jupyter-docker

# Configure glibc
ENV GLIBC_VER 2.32-r0

# Install glibc and useful packages
RUN echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    && apk --update add \
    bash \
    curl \
    ca-certificates \
    libstdc++ \
    glib \
    tini@testing \
    && curl "https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub" -o /etc/apk/keys/sgerrand.rsa.pub \
    && curl -L "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/$GLIBC_VER/glibc-$GLIBC_VER.apk" -o glibc.apk \
    && apk add glibc.apk \
    && curl -L "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/$GLIBC_VER/glibc-bin-$GLIBC_VER.apk" -o glibc-bin.apk \
    && apk add glibc-bin.apk \
    && curl -L "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/$GLIBC_VER/glibc-i18n-$GLIBC_VER.apk" -o glibc-i18n.apk \
    && apk add --allow-untrusted glibc-i18n.apk \
    && /usr/glibc-compat/bin/localedef -i en_US -f UTF-8 en_US.UTF-8 \
    && /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc/usr/lib \
    && rm -rf glibc*apk /var/cache/apk/*

# Configure environment
ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH
ENV SHELL /bin/bash
ENV CONTAINER_USER bob
ENV CONTAINER_UID 1000
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Configure Miniconda
ENV MINICONDA_VER 4.8.3
ENV PYTHON_VERSION 37
ENV MINICONDA Miniconda3-py${PYTHON_VERSION}_${MINICONDA_VER}-Linux-x86_64.sh
ENV MINICONDA_URL https://repo.continuum.io/miniconda/$MINICONDA
ENV MINICONDA_MD5_SUM 751786b92c00b1aeae3f017b781018df

# Create user with UID=1000 and in the 'users' group
RUN adduser -s /bin/bash -u $CONTAINER_UID -D $CONTAINER_USER && \
    mkdir -p /opt/conda && \
    chown $CONTAINER_USER /opt/conda

USER $CONTAINER_USER

# Install conda
RUN cd /tmp && \
    mkdir -p $CONDA_DIR && \
    curl -L $MINICONDA_URL  -o miniconda.sh  && \
    echo "$MINICONDA_MD5_SUM  miniconda.sh" | md5sum -c - && \
    /bin/bash miniconda.sh -f -b -p $CONDA_DIR && \
    rm miniconda.sh && \
    $CONDA_DIR/bin/conda install --yes conda==$MINICONDA_VER

RUN cd /tmp && \
    conda upgrade -y pip && \
    conda config --add channels conda-forge 
RUN conda install -c conda-forge requests urllib3 
RUN conda clean --all

USER root

# Configure container startup as root
WORKDIR /home/$CONTAINER_USER/
ENTRYPOINT ["/sbin/tini", "--"]
CMD [ "/bin/bash" ]

# Switch back to drtools to avoid accidental container runs as root
USER $CONTAINER_USER
