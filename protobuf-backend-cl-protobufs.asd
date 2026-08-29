(defsystem "protobuf-backend-cl-protobufs"
  :version "0.2.0"
  :description "egao1980/cl-protobufs backend for protobuf-protocol"
  :author "egao1980"
  :license "MIT"
  :depends-on ((:version "protobuf-protocol" "0.2.0") "uiop" "cl-protobufs")
  :properties (:cl-repo (:ci (:with ("dissect"))))
  :serial t
  :pathname "src"
  :components ((:file "package")
               (:file "backend")
               (:file "wkt"))
  :in-order-to ((test-op (test-op "protobuf-backend-cl-protobufs/tests"))))

(defsystem "protobuf-backend-cl-protobufs/tests"
  :depends-on ("protobuf-backend-cl-protobufs" "rove")
  :pathname "tests"
  :serial t
  :components ((:file "package")
               (:file "backend-test"))
  :perform (test-op (o c)
             (unless (symbol-call :rove :run c)
               (error "tests failed for ~A" (component-name c)))))
