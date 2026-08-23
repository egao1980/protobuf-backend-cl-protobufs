(in-package #:protobuf-backend-cl-protobufs)

(defclass cl-protobufs-backend (protobuf-protocol:protobuf-backend) ())

(defun make-cl-protobufs-backend ()
  (make-instance 'cl-protobufs-backend))

(defun use-cl-protobufs-backend ()
  (setf protobuf-protocol:*protobuf-backend* (make-cl-protobufs-backend)))
