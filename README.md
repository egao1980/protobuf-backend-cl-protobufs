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

Load **egao1980/cl-protobufs from GHCR via cl-repo**. WKT Lisp is vendored in
the source layer (`2.0-rc2+`) — no `protoc` at load. Unix overlays still ship
`protoc` + `protoc-gen-cl-pb` for compiling user `.proto` files.

```
sbcl --load scripts/live-protobuf.lisp
sbcl --load scripts/run-tests.lisp
```

Pin with `CL_PROTOBUFS_VERSION` (default `2.0-rc2`; `:latest` extracts 0 files).
`load-schema` still rejects `.proto`.

CI: canned [`cl-repository`](https://github.com/egao1980/cl-repository) (`test-system.yml` / `setup-client` + `ci`). Deps from `ghcr.io/egao1980/cl-systems`.

## License

MIT
