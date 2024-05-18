FROM nickblah/lua:5.4-luarocks-alpine

RUN apk add build-base bash

WORKDIR /pkger

COPY . .

RUN luarocks make --only-deps --lua-version=5.4 --local

RUN luarocks install luastatic

RUN make

RUN mv /bin/pkger /usr/local/bin

CMD [ "bash" ]
