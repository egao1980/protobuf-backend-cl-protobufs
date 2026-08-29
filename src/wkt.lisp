(in-package #:protobuf-backend-cl-protobufs)

;;; JSON-shaped Lisp ↔ google.protobuf.Value. yason's NIL is both JSON null
;;; and false; we encode NIL as NullValue. Explicit false is not recoverable
;;; from that representation — same collapse the rest of the stack lives with.
;;; schema-protocol's :null is NullValue.

(defun %maybe-int (number)
  "WKT numbers are doubles. Integer-valued doubles become integers so AG-UI
   counts and timestamps do not come back as 1.0d0."
  (cond
    ((not (floatp number)) number)
    ((not (= number number)) number)
    ((or (>= number most-positive-double-float)
         (<= number most-negative-double-float))
     number)
    ((= number (ftruncate number)) (truncate number))
    (t number)))

(defun %lisp-to-struct (table)
  (let ((struct (google:make-struct)))
    (maphash (lambda (key value)
               (setf (google:struct.fields-gethash
                      (if (stringp key) key (princ-to-string key))
                      struct)
                     (%lisp-to-value value)))
             table)
    struct))

(defun %lisp-to-value (value)
  (cond
    ((typep value 'google:value) value)
    ((eq value :null) (google:make-value :null-value :null-value))
    ((null value) (google:make-value :null-value :null-value))
    ((eq value t) (google:make-value :bool-value t))
    ((stringp value) (google:make-value :string-value value))
    ((integerp value) (google:make-value :number-value (float value 1.0d0)))
    ((realp value) (google:make-value :number-value (float value 1.0d0)))
    ((hash-table-p value)
     (google:make-value :struct-value (%lisp-to-struct value)))
    ((and (vectorp value) (not (stringp value)))
     (google:make-value :list-value
                        (google:make-list-value
                         :values (map 'list #'%lisp-to-value value))))
    ((listp value)
     (google:make-value :list-value
                        (google:make-list-value
                         :values (mapcar #'%lisp-to-value value))))
    ((symbolp value)
     (google:make-value :string-value (string-downcase (symbol-name value))))
    (t (google:make-value :string-value (princ-to-string value)))))

(defun %struct-to-lisp (struct)
  (let ((out (make-hash-table :test 'equal))
        (fields (and struct (google:fields struct))))
    (when (hash-table-p fields)
      (maphash (lambda (key value)
                 (setf (gethash key out) (%value-to-lisp value)))
               fields))
    out))

(defun %value-to-lisp (value)
  (cond
    ((null value) :null)
    ((cl-protobufs:has-field value 'google:string-value)
     (google:value.string-value value))
    ((cl-protobufs:has-field value 'google:number-value)
     (%maybe-int (google:value.number-value value)))
    ((cl-protobufs:has-field value 'google:bool-value)
     (google:value.bool-value value))
    ((cl-protobufs:has-field value 'google:null-value)
     :null)
    ((cl-protobufs:has-field value 'google:struct-value)
     (%struct-to-lisp (google:value.struct-value value)))
    ((cl-protobufs:has-field value 'google:list-value)
     (map 'vector #'%value-to-lisp
          (or (google:list-value.values (google:value.list-value value)) '())))
    (t :null)))

(defmethod protobuf-protocol:backend-wkt-value-class ((backend cl-protobufs-backend))
  (declare (ignore backend))
  'google:value)

(defmethod protobuf-protocol:backend-lisp-to-wkt ((backend cl-protobufs-backend) value)
  (declare (ignore backend))
  (%lisp-to-value value))

(defmethod protobuf-protocol:backend-wkt-to-lisp ((backend cl-protobufs-backend) message)
  (declare (ignore backend))
  (%value-to-lisp message))
