;;   The Computer Language Benchmarks Game
;;   http://shootout.alioth.debian.org/
;;;
;;; From: Manuel Giraud
;;; Nicer rewrite: Nicolas Neuss
;;; Modified by Juho Snellman 2005-10-26
;;;  * Change the node representation from a struct to an improper list
;;;    (saves 8 bytes for each node on SBCL/CMUCL)
;;;  * Use NIL for leaf nodes, as in the Haskell solution
;;;  * Add command-line parsing for non-CMUCL implementations
;;; De-optimized by Isaac Gouy
;;;
;;; Modified by Witali Kusnezow 2009-01-20
;;;  * simplified structure of leaf nodes
;;;  * optimize GC usage
;;;  * optimize all functions
;;;
;;; Modified by Marko Kocic 2009-06-23
;;;  * Adapted to run under ECL

;;; Node is either (DATA) (for leaf nodes) or an improper list (DATA LEFT . RIGHT)

(defun build-btree (item depth)
  (declare (fixnum item depth))
  (if (zerop depth) (list item)
      (let ((item2 (+ item item))
            (depth-1 (1- depth)))
        (declare (fixnum item2 depth-1))
        (cons item
              (cons (build-btree (the fixnum (1- item2)) depth-1)
                    (build-btree item2 depth-1))))))

(defun check-node (node)
  (declare (values fixnum))
  (let ((data (car node))
        (kids (cdr node)))
    (declare (fixnum data))
    (if kids
        (- (+ data (check-node (car kids)))
           (check-node (cdr kids)))
        data)))

(defun loop-depths (max-depth &key (min-depth 4))
  (declare (type fixnum max-depth min-depth))
  (loop for d of-type fixnum from min-depth by 2 upto max-depth do
       (loop with iterations of-type fixnum = (ash 1 (+ max-depth min-depth (- d)))
          for i of-type fixnum from 1 upto iterations
          sum (+ (the fixnum (check-node (build-btree i d)))
                 (the fixnum (check-node (build-btree (- i) d))))
          into result of-type fixnum
          finally
            (format t "~D trees of depth ~D check: ~D~%"
                    (the fixnum (+ iterations iterations )) d result))))

(defun main (&optional (n (parse-integer
                           (or (car (last #+sbcl sb-ext:*posix-argv*
                                          #+cmu  extensions:*command-line-strings*
                                          #+gcl  si::*command-args*
                                          #+ecl  (si:command-args)))
                               "1"))))
  (declare (type (integer 0 255) n))
  (format t "stretch tree of depth ~D check: ~D~%" (1+ n) (check-node (build-btree 0 (1+ n))))
  (let ((long-lived-tree (build-btree 0 n)))
    (loop-depths n)
    (format t "long lived tree of depth ~D check: ~D~%" n (check-node long-lived-tree))))

(main)

