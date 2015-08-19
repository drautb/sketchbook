#!/usr/bin/env racket

#lang racket

(require json)

;; CMD-LINE STUFF
(define verbose-mode (make-parameter #f))
(define project-type (make-parameter null))
(define is-srvps (make-parameter #f))
(define include-linter-settings (make-parameter #f))

(define generator-settings
  (command-line
    #:program "sublime-project generator"
    #:once-each
    [("-v" "--verbose") "Execute with verbose messages"
     (verbose-mode #t)]
    [("-t" "--type") type
     "Specify the project type"
     (project-type (string->symbol type))]
    [("-s" "--srvps") "Generate special config for a service provisioner"
     (is-srvps #t)]
    [("-l" "--lint") "Include SublimeLinter settings"
     (include-linter-settings #t)]))

;; todo: Macro that only prints things if --verbose is on.
(define (log form . values)
  (cond [(verbose-mode)
         (apply fprintf (current-output-port) (string-append form "~n") values)]))

;; CONSTANTS
(define FOLDERS 'folders)
(define FOLLOW-SYMLINKS 'follow_symlinks)
(define PATH 'path)
(define FOLDER-EXCLUDE-PATTERNS 'folder_exclude_patterns)

(define BUILD-SYSTEMS 'build_systems)
(define CMD 'cmd)
(define NAME 'name)
(define WORKING-DIR 'working_dir)
(define VARIANTS 'variants)

(define HOME-DIR (path->string (find-system-path 'home-dir)))
(define CURRENT-PATH (path->string (current-directory)))
(define CURRENT-DIR (path->string (last (explode-path (current-directory)))))
(define OUTPUT-FILE (string-append CURRENT-DIR ".sublime-project"))

(define SUBLIME-LINTER-SETTINGS 'SublimeLinter)
(define LINTERS 'linters)
(define WORKING-DIRECTORY 'working_directory)
(define ARGS 'args)

(define CLASSPATH-DELIMITER ":")

;; PROJECT SPECIFIC SETTINGS
(define FOLDER-EXCLUDE-PATTERNS-LOOKUP
  (hash 'maven (list "target")
        null (list)))

(define LINTER-NAME-LOOKUP
  (hash 'maven 'javac
        null null))

(define SRVPS-DEPENDENCIES
  (list "paas-sps-common"
        "paas-sps-config"
        "paas-sps-common-test"
        "paas-sps-launcher"
        "paas-sps-context"))

;; strip-trailing-slash : String -> String
;; Strips a trailing slash from the input string
(define (strip-trailing-slash str)
  (string-trim str "/" #:left? #f))

;; system->string : String -> String
;; Takes a string that will be executed as a shell cmd, and returns its output as a string.
(define (system->string cmd)
  (with-output-to-string (λ () (system cmd))))

;; extract-classpath-lines : String -> List of String
;; Given a string that is the output of `mvn dependency:build-classpath`, this
;; function will return a list of classpath strings. (One list per maven module)
(define (extract-classpath-lines mvn-cmd-output)
  (define MARKER "[INFO] Dependencies classpath:")
  (define (handle-next-line lines)
    (cond [(empty? lines) '()]
          [(equal? (first lines) MARKER) (cons (first (rest lines)) (handle-next-line (rest (rest lines))))]
          [else (handle-next-line (rest lines))]))
  (let ([lines (string-split mvn-cmd-output "\n")])
    (handle-next-line lines)))

;; assemble-complete-classpath : List of String -> String
;; Given a list of classpath strings, this function will combine them and remove
;; duplicate entries.
(define (assemble-complete-classpath classpaths)
  (string-join
    (remove-duplicates
      (string-split
        (string-join
          (remove* '("") classpaths)
          CLASSPATH-DELIMITER)
        CLASSPATH-DELIMITER))
    CLASSPATH-DELIMITER))

;; get-classpath : -> String
;; Executes a maven command to get the projects' classpaths, then assembles
;; and returns it using the functions above.
;; The assembled classpath is a single string containing full paths to artifacts,
;; delimited by ':'.
(define (get-classpath)
  (log "Determining classpath for javac linter...")
  (let ([mvn-build-classpath-output (system->string "mvn dependency:build-classpath")])
    (assemble-complete-classpath
      (append (extract-classpath-lines mvn-build-classpath-output)
              (list (get-paths-to-targets))))))

;; convert-paths-to-classpaths : String -> String
;; Takes the output of a system find command, and converts each resulting
;; file to a classpath.
(define (convert-paths-to-classpaths paths)
  (let ([paths (string-split paths "\n")])
    (string-trim
      (foldl (λ (next-path accumulated)
               (string-append accumulated CLASSPATH-DELIMITER
                              (string-replace (string-replace next-path "pom.xml" "target/classes") "./" "${project}/")))
             "" paths)
      CLASSPATH-DELIMITER)))

;; get-target-classpath : -> String
;; Uses the function above to construct a classpath that includes the target dirctories for a maven project.
(define (get-paths-to-targets)
  (let ([find-cmd-output (system->string "find . -name pom.xml")])
    (convert-paths-to-classpaths find-cmd-output)))

;; javac-linter-settings : String -> Hash
;; Given a classpath, this function generates the Hash that, when converted to JSON, configures
;; javac for the SublimeLinter plugin.
(define (javac-linter-settings classpath)
  (hash WORKING-DIRECTORY "."
        ARGS (list "-classpath"
                   classpath
                   "-Xlint" "-Xlint:-serial")))


;; dump-parameters : -> void
;; Logs the parameters for the script execution to the terminal.
(define (dump-parameters)
  (log (string-append "Generating project settings~n"
                      "  Type: ~a~n"
                      "  Home Directory: ~a~n"
                      "  Current Path: ~a~n"
                      "  Current Directory: ~a~n"
                      "  Output File: ~a~n")
       (project-type) HOME-DIR CURRENT-PATH CURRENT-DIR OUTPUT-FILE))

;; generate-folders-list : String, List of String -> List
;; Given a path, and a list of folder patterns to exclude, this function
;; generates the "folders" settings for a project.
(define (generate-folders-list path folder-exclude-patterns)
  (define default-list
    (list
      (hash FOLLOW-SYMLINKS #t
            PATH path
            FOLDER-EXCLUDE-PATTERNS folder-exclude-patterns)))
  (if (is-srvps)
      (append default-list (generate-srvps-folders-list folder-exclude-patterns))
      default-list))

(define (generate-srvps-folders-list folder-exclude-patterns)
  (for/list ([dependency SRVPS-DEPENDENCIES])
    (hash FOLLOW-SYMLINKS #t
          PATH (string-append "/Users/drautb/GitHub/fs-eng/" dependency)
          FOLDER-EXCLUDE-PATTERNS folder-exclude-patterns)))

(define (generate-maven-build-systems)
  (define (mvn-cmd cmd-name [name (string-titlecase cmd-name)])
    (hash CMD (list "mvn" "-B" "clean" cmd-name)
          NAME name
          WORKING-DIR (strip-trailing-slash CURRENT-PATH)))
  (list (hash-set (mvn-cmd "install" "Maven")
                  VARIANTS (map mvn-cmd (list "clean" "compile" "test" "package")))))

;; Generates the build systems for a project.
(define (generate-build-systems)
  (log "Generating build systems...")
  (cond [(equal? (project-type) 'maven) (generate-maven-build-systems)]
        [else (list)]))

(define (generate-linter-settings)
  (log "Generating linter settings...")
  (if (equal? (project-type) 'maven)
      (let ([linter (hash-ref LINTER-NAME-LOOKUP (project-type))])
        (hash LINTERS
              (hash linter (javac-linter-settings (get-classpath)))))
      (hash)))

;; Generates the entire settings object
(define (generate-settings)
  (dump-parameters)
  (let ([settings-hash (make-hash)])
    (hash-set! settings-hash FOLDERS (generate-folders-list "." (hash-ref FOLDER-EXCLUDE-PATTERNS-LOOKUP (project-type))))
    (hash-set! settings-hash BUILD-SYSTEMS (generate-build-systems))
    (cond [(include-linter-settings)
           (hash-set! settings-hash SUBLIME-LINTER-SETTINGS (generate-linter-settings))])
    settings-hash))

(define (create-project-file)
  (let ([output-file-port (open-output-file OUTPUT-FILE #:exists 'replace)]
        [project-settings (generate-settings)])
    (log "Writing '~a':~n~n~a~n" OUTPUT-FILE (jsexpr->bytes project-settings))
    (write-json project-settings output-file-port)))

(provide strip-trailing-slash
         extract-classpath-lines
         assemble-complete-classpath
         convert-paths-to-classpaths
         javac-linter-settings
         generate-folders-list)

(create-project-file)
