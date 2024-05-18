FROM nickblah/lua:5.4-luarocks

RUN apt-get update && apt-get install -y build-essential

WORKDIR /pkger

COPY . .

# RUN luarocks make --only-deps --lua-version=5.4 --local

# RUN luarocks install luastatic

CMD [ "bash" ]
