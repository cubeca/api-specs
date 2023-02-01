FROM stoplight/prism:4

COPY build/bff-auth-filtered.yaml /build/bff-auth-filtered.yaml

# $ node /usr/local/bin/prism mock --help
# prism mock <document>
#
# Start a mock server with the given document file
#
# Positionals:
#   document  Path to a document file. Can be both a file or a fetchable resource on the web.                                            [string] [required]
#
# Options:
#       --version       Show version number                                                                                                        [boolean]
#       --help          Show help                                                                                                                  [boolean]
#   -p, --port          Port that Prism will run on.                                                                     [number] [required] [default: 4010]
#   -h, --host          Host that Prism will listen to.                                                           [string] [required] [default: "127.0.0.1"]
#       --cors          Enables CORS headers.                                                                                      [boolean] [default: true]
#   -m, --multiprocess  Forks the http server from the CLI for faster log processing.                                              [boolean] [default: true]
#       --errors        Specifies whether request/response violations marked as errors will produce an error response  [boolean] [required] [default: false]
#   -d, --dynamic       Dynamically generate examples.                                                                            [boolean] [default: false]
#
#
#
# Use `--dynamic` to enable dynamic responses (i.e. not from examples, but from constraints in JSON schemas)
ENTRYPOINT ["node", "/usr/local/bin/prism", "mock", "--host", "0.0.0.0", "/build/bff-auth-filtered.yaml"]

EXPOSE 4010
