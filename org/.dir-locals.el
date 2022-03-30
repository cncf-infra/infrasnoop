((
  org-mode
  .
  (
   (
    eval
    .
    (progn
      (message "START: ii/sql-org-hacks")
      (defun reconfigure-org ()
        (interactive)
      (set (make-local-variable 'org-babel-default-header-args:sql-mode)
            ;; Set up all sql-mode blocks to be postgres and literate
            '((:results . "replace code")
              (:product . "postgres")
              (:session . "infrasnoop")
              (:noweb . "yes")
              (:comments . "no")
              (:wrap . "SRC example")))
      (set (make-local-variable 'sql-server)
           (if (getenv "PGHOST")
               (getenv "PGHOST")
             (if (file-exists-p "/var/run/secrets/kubernetes.io/serviceaccount/namespace")
                 "infra-db.infrasnoop"
               "localhost"
               )))
      (set (make-local-variable 'sql-port)
           (if (getenv "PGPORT")
               (string-to-number (getenv "PGPORT"))
             5432))
      (set (make-local-variable 'sql-user)
           (if (getenv "PGUSER")
               (getenv "PGUSER")
             "infrasnoop"))
      (set (make-local-variable 'sql-database)
           (if (getenv "PGDATABASE")
               (getenv "PGDATABASE")
             "infrasnoop"))
      (set (make-local-variable 'sql-password)
           (if (getenv "PGPASSWORD")
               (getenv "PGPASSWORD")
             "infrasnoop"))
      (set (make-local-variable 'sql-product)
           '(quote postgres))
      (set (make-local-variable 'sql-connection-alist)
           (list
            ;; setting these allows for the connection to be
            ;; created on the fly
            (list 'infrasnoop
                  (list 'sql-product '(quote postgres))
                  (list 'sql-database (concat "postgresql://"
                                          sql-user
                                          ":" sql-password
                                          "@" sql-server
                                          ":" (number-to-string sql-port)
                                          "/" sql-database ;; replace with your database
                                          "?ssmode=require"
                                          )))))
      )
      (reconfigure-org)
      (message "END: ii/sql-org-hacks")
      )))))
