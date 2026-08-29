(defpackage #:protobuf-backend-cl-protobufs
  (:use #:cl)
  (:local-nicknames (#:google #:cl-protobufs.google.protobuf))
  (:export #:cl-protobufs-backend
           #:make-cl-protobufs-backend
           #:use-cl-protobufs-backend))

(in-package #:protobuf-backend-cl-protobufs)
