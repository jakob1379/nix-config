FROM python:3.13-slim

WORKDIR /workspace

COPY ./scripts/serve.sh /usr/local/bin/serve.sh
RUN chmod +x /usr/local/bin/serve.sh

COPY . /workspace

EXPOSE 8000

CMD ["/usr/local/bin/serve.sh"]
