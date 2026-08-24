;;;; Local Rove via cl-repo (OCI cl-protobufs overlay).
;;;;   sbcl --load scripts/run-tests.lisp

(setf *debugger-hook*
      (lambda (c h)
        (declare (ignore h))
        (format *error-output* "~&run-tests failed: ~a~%" c)
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

(defun %sut-dirs ()
  (list (merge-pathnames "protobuf-backend-cl-protobufs/" (%workspace))
        (merge-pathnames "protobuf-protocol/" (%workspace))))

(defun %bind-consumer-asdf ()
  "OCI systems-root + local SUTs. Drop workspace inherit so git cl-protobufs
   (needs protoc) cannot shadow the GHCR overlay."
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
     :version (or (uiop:getenv "CL_PROTOBUFS_VERSION") "2.0-rc1")
     :default-source :oci)
   (cl-repo:ensure-systems '("serdes-protocol" "rove") :default-source :oci)
   (cl-repo:ensure-system-dependencies "protobuf-backend-cl-protobufs"
     :also-tests t
     :default-source :oci)))
(%bind-consumer-asdf)
(cl-repository-client/asdf-integration:load-system-init-files)
(%muffle (lambda () (asdf:test-system "protobuf-backend-cl-protobufs")))
(format t "~&; protobuf-backend-cl-protobufs tests ok~%")
(uiop:quit 0)
