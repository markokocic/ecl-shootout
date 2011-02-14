(require 'cmp)

(defun create-exec (file)
  (let ((c::*cc-flags* " -O3 -march=core2 -fomit-frame-pointer -fPIC  -Ic:/usr/local/include "))
    (c::builder :program file
                :lisp-files (list (compile-file file :system-p t))
                :epilogue-code '(quit))))
