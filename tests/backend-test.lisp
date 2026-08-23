(in-package #:protobuf-backend-cl-protobufs/tests)

(deftest backend-class
  (ok (typep (protobuf-backend-cl-protobufs:make-cl-protobufs-backend) 'protobuf-backend-cl-protobufs:cl-protobufs-backend)))
