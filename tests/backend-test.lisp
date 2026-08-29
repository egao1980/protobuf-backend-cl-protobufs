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

(defun %ht (&rest kvs)
  (let ((h (make-hash-table :test 'equal)))
    (loop for (k v) on kvs by #'cddr
          do (setf (gethash k h) v))
    h))

(defun %json-equal (a b)
  (cond
    ((and (hash-table-p a) (hash-table-p b))
     (and (= (hash-table-count a) (hash-table-count b))
          (loop for k being the hash-keys of a using (hash-value av)
                always (%json-equal av (gethash k b)))))
    ((and (vectorp a) (not (stringp a)) (vectorp b) (not (stringp b)))
     (and (= (length a) (length b))
          (loop for x across a for y across b always (%json-equal x y))))
    (t (equal a b))))

(deftest wkt-scalars-roundtrip
  (ok (eq :null (protobuf-protocol:decode-wkt (protobuf-protocol:encode-wkt :null))))
  (ok (eq :null (protobuf-protocol:decode-wkt (protobuf-protocol:encode-wkt nil))))
  (ok (eq t (protobuf-protocol:decode-wkt (protobuf-protocol:encode-wkt t))))
  (ok (equal "hi" (protobuf-protocol:decode-wkt (protobuf-protocol:encode-wkt "hi"))))
  (ok (eql 12 (protobuf-protocol:decode-wkt (protobuf-protocol:encode-wkt 12))))
  (ok (= 1.5d0 (protobuf-protocol:decode-wkt (protobuf-protocol:encode-wkt 1.5d0)))))

(deftest wkt-object-and-array-roundtrip
  (let* ((doc (%ht "type" "TEXT_MESSAGE_CONTENT"
                   "messageId" "m"
                   "delta" "hi"
                   "nested" (%ht "n" 1)
                   "tags" #("a" "b")))
         (back (protobuf-protocol:decode-wkt (protobuf-protocol:encode-wkt doc))))
    (ok (%json-equal doc back))))

(deftest wkt-serdes-roundtrip
  (let* ((doc (%ht "type" "RUN_STARTED" "threadId" "t" "runId" "r"))
         (octets (serdes-protocol:encode doc :format :wkt))
         (back (serdes-protocol:decode octets :format :wkt)))
    (ok (typep octets '(vector (unsigned-byte 8))))
    (ok (%json-equal doc back))))

(deftest wkt-length-prefixed-stream
  (uiop:with-temporary-file (:pathname path :prefix "wkt-ld-")
    (with-open-file (out path :direction :output
                              :element-type '(unsigned-byte 8)
                              :if-exists :supersede)
      (let ((s (serdes-protocol:make-output-stream
                out :format :wkt :element-type '(unsigned-byte 8))))
        (serdes-protocol:stream-encode-value s (%ht "n" 1))
        (serdes-protocol:stream-encode-value s "xy")))
    (with-open-file (in path :direction :input :element-type '(unsigned-byte 8))
      (let ((s (serdes-protocol:make-input-stream
                in :format :wkt :element-type '(unsigned-byte 8))))
        (ok (eql 1 (gethash "n" (serdes-protocol:stream-decode-value s))))
        (ok (equal "xy" (serdes-protocol:stream-decode-value s)))
        (ok (eq :eof (serdes-protocol:stream-decode-value s)))))))

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
