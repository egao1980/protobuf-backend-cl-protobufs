;;;; Dogfood cl-protobufs backend + serdes :protobuf.
;;;;   sbcl --load scripts/live-protobuf.lisp

(setf *debugger-hook*
      (lambda (c h)
        (declare (ignore h))
        (format *error-output* "~&live-protobuf failed: ~a~%" c)
        (uiop:quit 1)))

(defun %here ()
  (uiop:pathname-directory-pathname
   (or *load-truename* *compile-file-truename* (uiop:getcwd))))

(defun %root ()
  (uiop:pathname-parent-directory-pathname (%here)))

(defun %workspace ()
  (uiop:pathname-parent-directory-pathname (%root)))

(dolist (name '("protobuf-protocol" "protobuf-backend-cl-protobufs"
                "serdes-protocol" "cl-protobufs"))
  (pushnew (merge-pathnames (format nil "~a/" name) (%workspace))
           asdf:*central-registry* :test #'equal))

(asdf:load-system "protobuf-backend-cl-protobufs")

(eval-when (:compile-toplevel :load-toplevel :execute)
  (cl-protobufs.implementation:define-schema 'live-schema
    :syntax :proto3
    :package 'protobuf_live)
  (cl-protobufs.implementation:define-message live-ping ()
    (payload :index 1 :type cl:string :label (:optional) :typename "string")))

(defun fail (fmt &rest args)
  (apply #'format *error-output* (concatenate 'string "~&FAIL: " fmt "~%") args)
  (uiop:quit 1))

(let* ((msg (make-live-ping :payload "ok"))
       (octets (protobuf-protocol:encode-to-octets msg))
       (back (protobuf-protocol:decode-octets octets 'live-ping)))
  (unless (equal "ok" (live-ping.payload back))
    (fail "roundtrip payload"))
  (let ((protobuf-protocol:*protobuf-message-class* 'live-ping))
    (unless (equal "ok" (live-ping.payload
                         (serdes-protocol:decode
                          (serdes-protocol:encode msg :format :protobuf)
                          :format :protobuf)))
      (fail "serdes :protobuf"))))

(format t "~&; protobuf-backend-cl-protobufs live ok~%")
(uiop:quit 0)
