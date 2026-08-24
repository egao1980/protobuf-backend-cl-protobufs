(in-package #:protobuf-backend-cl-protobufs/tests)

(deftest backend-class
  (ok (typep (protobuf-backend-cl-protobufs:make-cl-protobufs-backend)
             'protobuf-backend-cl-protobufs:cl-protobufs-backend)))

(deftest auto-selects-backend
  (ok (typep protobuf-protocol:*protobuf-backend*
             'protobuf-backend-cl-protobufs:cl-protobufs-backend)))

(deftest encode-decode-roundtrip
  (let* ((msg (google:make-string-value :value "hello"))
         (octets (protobuf-protocol:encode-to-octets msg))
         (back (protobuf-protocol:decode-octets octets 'google:string-value)))
    (ok (typep octets '(vector (unsigned-byte 8))))
    (ok (plusp (length octets)))
    (ok (equal "hello" (google:string-value.value back)))))

(deftest empty-message
  (let* ((msg (google:make-string-value))
         (octets (protobuf-protocol:encode-to-octets msg))
         (back (protobuf-protocol:decode-octets octets 'google:string-value)))
    (ok (zerop (length octets)))
    (ok (equal "" (or (google:string-value.value back) "")))))

(deftest serdes-octets
  ;; serdes 0.2.0 encode-to-octets UTF-8s the payload; use encode/decode
  ;; (octets) until 0.2.1 pass-through is published.
  (let* ((protobuf-protocol:*protobuf-message-class* 'google:string-value)
         (msg (google:make-string-value :value "serdes"))
         (octets (serdes-protocol:encode msg :format :protobuf))
         (back (serdes-protocol:decode octets :format :protobuf)))
    (ok (typep octets '(vector (unsigned-byte 8))))
    (ok (equal "serdes" (google:string-value.value back)))))

(deftest load-schema-rejects-proto
  (ok (signals (protobuf-protocol:load-schema #p"ping.proto")
               'protobuf-protocol:protobuf-schema-error))
  (ok (signals (protobuf-protocol:load-schema "foo.proto")
               'protobuf-protocol:protobuf-schema-error)))

(deftest encode-to-stream-roundtrip
  (uiop:with-temporary-file (:pathname path :prefix "pb-live-")
    (let ((msg (google:make-string-value :value "file")))
      (with-open-file (out path :direction :output
                                :element-type '(unsigned-byte 8)
                                :if-exists :supersede)
        (protobuf-protocol:encode-message msg :stream out))
      (with-open-file (in path :direction :input :element-type '(unsigned-byte 8))
        (let ((back (protobuf-protocol:decode-message in 'google:string-value)))
          (ok (equal "file" (google:string-value.value back))))))))
