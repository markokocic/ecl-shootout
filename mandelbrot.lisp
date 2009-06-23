;;   The Computer Language Benchmarks Game
;;   http://shootout.alioth.debian.org/
;;;
;;; contributed by Yannick Gingras
;;; modified by Wade Humeniuk (Fix Stream Problem)
;;; parallelised by Paul Khuong

(deftype index ()
  '(and unsigned-byte fixnum))

(declaim (inline in-set-p))
(defun in-set-p (base-real base-imag
                 &optional (if-true t) (if-false nil))
  (declare (type double-float base-real base-imag)
           (optimize speed))
  (let ((zr base-real)
        (zi base-imag))
    (declare (type double-float zr zi))
    (dotimes (n 50 if-true)
      (let ((zr^2 (* zr zr))
            (zi^2 (* zi zi)))
        (when (>= (+ zr^2 zi^2) 4d0)
          (return if-false))
        (psetf zr (+ (- zr^2 zi^2)
                     base-real)
               zi (+ (let ((mul (* zr zi)))
                       (+ mul mul))
                     base-imag))))))

(defun render (size stream &optional (nproc 1))
  (declare (type (integer 8 10000) size)
           (stream stream)
           (type (integer 1) nproc)
	   (optimize speed))
  (assert (zerop (mod size 8)))

  (let* ((delta   (/ 2d0 size))
         (buffer  (make-array (* size (ceiling size 8))
                              :element-type '(unsigned-byte 8)))
         (cur-row (list 0)))
    (labels ((compute-row (base-imag row-index)
               (declare (type double-float base-imag)
                        (type index row-index)
                        (optimize (safety 1)))
               (loop for x     of-type index below size by 8
                     for index of-type index upfrom row-index
                     for code  of-type (unsigned-byte 8) = 0
                     do
                  (dotimes (xp 8)
                    (setf code (logior (ash code 1)
                                       (in-set-p (+ -1.5d0 (* delta (+ x xp)))
                                                 base-imag
                                                 1
                                                 0))))
                  (setf (aref buffer index) code)))
             (get-next-row ()
               ;; sb-ext:atomic-incf since 1.0.21
               (loop for old-y of-type index = (car cur-row)
                     when (eq old-y (sb-ext:compare-and-swap
                                     (car cur-row) old-y (1+ old-y)))
                       do (return old-y)))
             (compute-rows ()
               (loop for y = (get-next-row)
                     while (< y size)
                     do (let ((base-imag (- 1.0d0 (* delta y))))
                          (compute-row base-imag (* y (floor size 8)))))
               nil))
      (if (= nproc 1)
        (compute-rows)
        #+sb-thread
        (mapc #'sb-thread:join-thread
              (loop repeat nproc
                    collect (sb-thread:make-thread #'compute-rows)))
        #-sb-thread
        (error "Can't use multiple processors on single-threaded builds")))

    (write-sequence buffer stream)))

(defun main ()
  (let* ((args    (si:command-argv)
	 (n       (parse-integer (second args)))
         (nthread (parse-integer (or (third args)
                                     "4"))))
    (with-open-stream (stream (sb-sys:make-fd-stream
                               (sb-sys:fd-stream-fd sb-sys:*stdout*)
                               :element-type :default
                               :buffering :full
                               :output t :input nil))
      (format stream "P4~%~d ~d~%" n n)
      (render n stream nthread)
      (force-output stream))))

(main)
