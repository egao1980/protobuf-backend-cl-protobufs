(in-package #:protobuf-backend-cl-protobufs/tests)

(deftest backend-class
  (ok (typep (protobuf-backend-cl-protobufs:make-cl-protobufs-backend)
             'protobuf-backend-cl-protobufs:cl-protobufs-backend)))

(deftest auto-selects-backend
  (ok (typep protobuf-protocol:*protobuf-backend*
             'protobuf-backend-cl-protobufs:cl-protobufs-backend)))

(deftest encode-decode-roundtrip
  (let* ((msg (make-ping :payload "hello"))
         (octets (protobuf-protocol:encode-to-octets msg))
         (back (protobuf-protocol:decode-octets octets 'ping)))
    (ok (typep octets '(vector (unsigned-byte 8))))
    (ok (plusp (length octets)))
    (ok (equal "hello" (ping.payload back)))))

(deftest empty-message
  (let* ((msg (make-ping))
         (octets (protobuf-protocol:encode-to-octets msg))
         (back (protobuf-protocol:decode-octets octets 'ping)))
    (ok (zerop (length octets)))
    (ok (equal "" (or (ping.payload back) "")))))

(deftest serdes-octets
  (let* ((protobuf-protocol:*protobuf-message-class* 'ping)
         (msg (make-ping :payload "serdes"))
         (octets (serdes-protocol:encode-to-octets msg :format :protobuf))
         (back (serdes-protocol:decode-octets octets :format :protobuf)))
    (ok (typep octets '(vector (unsigned-byte 8))))
    (ok (equal "serdes" (ping.payload back)))))

(deftest load-schema-rejects-proto
  (ok (signals (protobuf-protocol:load-schema #p"ping.proto")
               'protobuf-protocol:protobuf-schema-error))
  (ok (signals (protobuf-protocol:load-schema "foo.proto")
               'protobuf-protocol:protobuf-schema-error)))

(deftest encode-to-stream-roundtrip
  (uiop:with-temporary-file (:pathname path :prefix "pb-live-")
    (let ((msg (make-ping :payload "file")))
      (with-open-file (out path :direction :output
                                :element-type '(unsigned-byte 8)
                                :if-exists :supersede)
        (protobuf-protocol:encode-message msg :stream out))
      (with-open-file (in path :direction :input :element-type '(unsigned-byte 8))
        (let ((back (protobuf-protocol:decode-message in 'ping)))
          (ok (equal "file" (ping.payload back))))))))
