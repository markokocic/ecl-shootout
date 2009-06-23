(require 'cmp)

(defun create-exec (file)
  (c::builder :program file
              :lisp-files (list (compile-file file :system-p t))
              :epilogue-code '(resume)))
