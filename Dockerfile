FROM nickblah/lua:5.4-luarocks

RUN apt-get update \
  && apt-get install -y build-essential libssl-dev libcurl4-openssl-dev wget tar git

RUN wget https://curl.se/download/curl-8.7.1.tar.gz \
    && tar -xf curl-8.7.1.tar.gz \
    && cd curl-8.7.1 \
    && ./configure --with-openssl \
    && make \
    && make install

WORKDIR /pkger

COPY . .

RUN luarocks make --only-deps --lua-version=5.4

RUN luarocks install luastatic

RUN make

RUN echo 'export PATH=$PATH:/pkger/bin' >> ~/.bashrc

RUN echo 'export PATH="$HOME/.local/share/pkger/bin/:$PATH"' >> ~/.bashrc

RUN ./bin/pkger --help

CMD [ "bash" ]
