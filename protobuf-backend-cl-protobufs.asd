(defsystem "protobuf-backend-cl-protobufs"
  :version "0.1.1"
  :description "egao1980/cl-protobufs backend for protobuf-protocol"
  :author "egao1980"
  :license "MIT"
  :depends-on ("protobuf-protocol" "uiop" "cl-protobufs")
  :serial t
  :pathname "src"
  :components ((:file "package")
               (:file "backend"))
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
