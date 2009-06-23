(require 'cmp)

(defun create-exec (file)
  (let ((c::*cc-flags* " -O3 -march=i686 -fomit-frame-pointer -D_GNU_SOURCE -D_FILE_OFFSET_BITS=64 -fPIC -D_THREAD_SAFE  -Dlinux "))
    (c::builder :program file
                :lisp-files (list (compile-file file :system-p t))
                :epilogue-code '(resume))))
