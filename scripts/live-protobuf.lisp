;;;; Dogfood egao1980/cl-protobufs backend + serdes :protobuf.
;;;; Deps via cl-repo (OCI overlay). Local SUT + unpublished protobuf-protocol only.
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

(defun %muffle (fn)
  #+sbcl
  (handler-bind ((sb-ext:defconstant-uneql #'continue))
    (funcall fn))
  #-sbcl
  (funcall fn))

(defun %cl-protobufs-version ()
  (or (uiop:getenv "CL_PROTOBUFS_VERSION") "2.0-rc1"))

(defun %sut-dirs ()
  (list (merge-pathnames "protobuf-backend-cl-protobufs/" (%workspace))
        (merge-pathnames "protobuf-protocol/" (%workspace))))

(defun %bind-consumer-asdf ()
  (asdf:initialize-source-registry
   `(:source-registry
     (:tree ,(namestring
              (merge-pathnames ".local/share/cl-repository/systems/"
                               (user-homedir-pathname))))
     ,@(loop for d in (%sut-dirs)
             collect `(:directory ,(namestring d)))
     :ignore-inherited-configuration)))

(%muffle (lambda () (asdf:load-system "cl-repository-client")))
(cl-repo:add-registry "https://ghcr.io" :namespace "egao1980/cl-systems" :priority :prepend)
(%bind-consumer-asdf)
(%muffle
 (lambda ()
   (cl-repo:ensure-systems "cl-protobufs"
     :version (%cl-protobufs-version)
     :default-source :oci)
   (cl-repo:ensure-systems "serdes-protocol" :default-source :oci)
   (cl-repo:ensure-system-dependencies "protobuf-backend-cl-protobufs"
     :also-tests nil
     :default-source :oci)))
(%bind-consumer-asdf)
(cl-repository-client/asdf-integration:load-system-init-files)
(%muffle (lambda () (asdf:load-system "protobuf-backend-cl-protobufs")))

(defun fail (fmt &rest args)
  (apply #'format *error-output* (concatenate 'string "~&FAIL: " fmt "~%") args)
  (uiop:quit 1))

(let* ((msg (cl-protobufs.google.protobuf:make-string-value :value "ok"))
       (octets (protobuf-protocol:encode-to-octets msg))
       (back (protobuf-protocol:decode-octets
              octets 'cl-protobufs.google.protobuf:string-value)))
  (unless (equal "ok" (cl-protobufs.google.protobuf:string-value.value back))
    (fail "roundtrip payload"))
  (let ((protobuf-protocol:*protobuf-message-class*
          'cl-protobufs.google.protobuf:string-value))
    (unless (equal "ok" (cl-protobufs.google.protobuf:string-value.value
                         (serdes-protocol:decode
                          (serdes-protocol:encode msg :format :protobuf)
                          :format :protobuf)))
      (fail "serdes :protobuf"))))

(format t "~&; protobuf-backend-cl-protobufs live ok~%")
(uiop:quit 0)
