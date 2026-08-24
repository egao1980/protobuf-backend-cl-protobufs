(in-package #:protobuf-backend-cl-protobufs)

(defclass cl-protobufs-backend (protobuf-protocol:protobuf-backend) ())

(defun make-cl-protobufs-backend ()
  (make-instance 'cl-protobufs-backend))

(defun use-cl-protobufs-backend ()
  (let ((backend (make-cl-protobufs-backend)))
    (setf protobuf-protocol:*protobuf-backend* backend)
    (protobuf-protocol:use-protobuf-serdes-backend)
    backend))

(defun %message-type (message-class)
  (etypecase message-class
    (symbol message-class)
    (class (class-name message-class))))

(defmethod protobuf-protocol:backend-encode-message ((backend cl-protobufs-backend)
                                                     message &key stream)
  (handler-case
      (if stream
          (progn
            (cl-protobufs:serialize-to-stream message stream)
            (values))
          (cl-protobufs:serialize-to-bytes message))
    (protobuf-protocol:protobuf-error (e) (error e))
    (error (e)
      (error 'protobuf-protocol:protobuf-encode-error
             :message (format nil "~A" e)))))

(defmethod protobuf-protocol:backend-decode-message ((backend cl-protobufs-backend)
                                                     source message-class &key)
  (let ((type (%message-type message-class)))
    (handler-case
        (etypecase source
          (stream (cl-protobufs:deserialize-from-stream type source))
          ((vector (unsigned-byte 8))
           (cl-protobufs:deserialize-from-bytes type source)))
      (protobuf-protocol:protobuf-error (e) (error e))
      (error (e)
        (error 'protobuf-protocol:protobuf-decode-error
               :message (format nil "~A" e))))))

(defmethod protobuf-protocol:backend-load-schema ((backend cl-protobufs-backend) source &key)
  "Load a compiled schema. SOURCE = .lisp pathname, ASDF system name, or symbol.
   .proto files are rejected — compile via cl-protobufs.asdf / protoc first."
  (handler-case
      (etypecase source
        (pathname
         (let ((type (string-downcase (or (pathname-type source) ""))))
           (cond
             ((string= type "proto")
              (error 'protobuf-protocol:protobuf-schema-error
                     :message "load-schema does not compile .proto — use cl-protobufs.asdf / protoc, then load the generated lisp"))
             ((or (string= type "lisp") (string= type "lsp") (string= type ""))
              (load source))
             (t
              (error 'protobuf-protocol:protobuf-schema-error
                     :message (format nil "unsupported schema source type ~S" type))))))
        (string
         (cond
           ((let ((len (length source)))
              (and (>= len 6)
                   (string-equal source ".proto" :start1 (- len 6))))
            (error 'protobuf-protocol:protobuf-schema-error
                   :message "load-schema does not compile .proto — use cl-protobufs.asdf / protoc"))
           ((probe-file source)
            (load source))
           (t (asdf:load-system source))))
        (symbol
         (asdf:load-system source)))
    (protobuf-protocol:protobuf-error (e) (error e))
    (error (e)
      (error 'protobuf-protocol:protobuf-schema-error
             :message (format nil "~A" e)))))

(eval-when (:load-toplevel :execute)
  (use-cl-protobufs-backend))
