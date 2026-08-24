# protobuf-backend-cl-protobufs

Backend for [`protobuf-protocol`](https://github.com/egao1980/protobuf-protocol)
over the workspace fork [`egao1980/cl-protobufs`](https://github.com/egao1980/cl-protobufs)
(qitab/cl-protobufs + overlays / `protoc-gen-cl-pb`). Not upstream qitab.

```lisp
(asdf:load-system "protobuf-backend-cl-protobufs")

(protobuf-protocol:encode-to-octets message)
(protobuf-protocol:decode-octets octets 'my-package:my-message)
```

Loading the system sets `*protobuf-backend*` and registers serdes `:protobuf`.
`load-schema` loads generated `.lisp` / ASDF systems — it does not run protoc.

Load **egao1980/cl-protobufs from GHCR via cl-repo** (overlay = generated WKT +
`protoc-gen-cl-pb`). Do not `asdf:load-system` the workspace git checkout — that
path shells out to `protoc`.

```
sbcl --load scripts/live-protobuf.lisp
sbcl --load scripts/run-tests.lisp
```

Pin with `CL_PROTOBUFS_VERSION` (default `2.0-rc1`; `:latest` extracts 0 files).

CI: `setup-client` + `setup-roswell` + `scripts/ci-install.lisp` / `ci-test.lisp` (OCI only, no Quicklisp).

## License

MIT
