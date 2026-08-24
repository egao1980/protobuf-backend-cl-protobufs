(defpackage #:protobuf-backend-cl-protobufs/tests
  (:use #:cl #:rove)
  #-win32
  (:local-nicknames (#:google #:cl-protobufs.google.protobuf)))

(in-package #:protobuf-backend-cl-protobufs/tests)
