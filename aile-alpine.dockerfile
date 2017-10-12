FROM frolvlad/alpine-glibc:alpine-3.6
MAINTAINER Rosco Pecoltran <https://github.com/roscopecoltran>

# build: docker build -t aile:alpine -f aile-alpine.dockerfile --no-cache .
# run: docker run --rm -ti -p 2312:2312 -v `pwd`:/app aile:alpine

ENV CONDA_DIR="/opt/conda" \
    PATH="$CONDA_DIR/bin:$PATH" \
    CFLAGS=-I/usr/lib/python2.7/site-packages/numpy/core/include \
    PYTHONDONTWRITEBYTECODE=${PYTHONDONTWRITEBYTECODE:-"1"}

# Install conda
RUN CONDA_VERSION="4.0.5" && \
    CONDA_MD5_CHECKSUM="42dac45eee5e58f05f37399adda45e85" && \
    \
    apk add --no-cache --virtual=.build-dependencies wget ca-certificates bash && \
    \
    mkdir -p "$CONDA_DIR" && \
    wget "http://repo.continuum.io/miniconda/Miniconda2-${CONDA_VERSION}-Linux-x86_64.sh" -O miniconda.sh && \
    echo "$CONDA_MD5_CHECKSUM  miniconda.sh" | md5sum -c && \
    bash miniconda.sh -f -b -p "$CONDA_DIR" && \
    echo "export PATH=$CONDA_DIR/bin:\$PATH" > /etc/profile.d/conda.sh && \
    rm miniconda.sh && \
    \
    conda update --all --yes && \
    conda config --set auto_update_conda False && \
    rm -r "$CONDA_DIR/pkgs" && \
    \
    apk del --purge .build-dependencies && \
    \
    mkdir -p "$CONDA_DIR/locks" && \
    chmod 777 "$CONDA_DIR/locks"

COPY requirements.txt /app
WORKDIR /app

# pip install --upgrade pip setuptools
# echo "http://dl-4.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories
RUN apk add --no-cache libstdc++ bash nano cython git libx11 && \
    apk add --no-cache \
        --virtual=.build-dependencies \
        g++ gfortran musl-dev cython-dev libx11-dev gcc linux-headers lapack-dev \
        python3-dev && \
    ln -s locale.h /usr/include/xlocale.h && \
    pip install numpy && \
    pip install pandas && \
    pip install scipy && \
    pip install scikit-learn && \
	pip install -r requirements.txt && \
    find /usr/lib/python3.*/ -name 'tests' -exec rm -r '{}' + && \
    rm /usr/include/xlocale.h && \
    rm -r /root/.cache && \
    apk del .build-dependencies 

COPY . /app

VOLUNES ["/data"]
EXPOSE 2312

RUN python setup.py develop

CMD ["/bin/bash"]