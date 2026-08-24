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

```
sbcl --load scripts/live-protobuf.lisp
```

CI: `setup-client` + `setup-roswell` + `scripts/ci-install.lisp` / `ci-test.lisp` (OCI only, no Quicklisp).

## License

MIT
