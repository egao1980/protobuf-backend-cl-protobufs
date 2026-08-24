(in-package #:protobuf-backend-cl-protobufs/tests)

;;; Lisp-defined proto (no protoc). Used by backend tests + load-schema.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (cl-protobufs.implementation:define-schema 'ping-schema
    :syntax :proto3
    :package 'protobuf_backend_test)
  (cl-protobufs.implementation:define-message ping ()
    (payload :index 1 :type cl:string :label (:optional) :typename "string")))
