#!/usr/bin/env racket

#lang racket

(require json)

;; CMD-LINE STUFF
(define verbose-mode (make-parameter #f))
(define project-type (make-parameter null))
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


;; PROJECT SPECIFIC SETTINGS
(define FOLDER-EXCLUDE-PATTERNS-LOOKUP
  (hash 'maven (list "target")
        null (list)))

(define LINTER-NAME-LOOKUP
  (hash 'maven 'javac
        null null))

(define (get-classpath)
  (define (find-classpath lines)
    (let ([current-line (first lines)])
      (if (equal? (string-ref current-line 0) #\[)
          (find-classpath (rest lines))
          current-line)))
  (log "Executing mvn dependency:build-classpath...")
  (let ([output-lines (string-split (with-output-to-string (λ () (system "mvn dependency:build-classpath"))) "\n")])
    (find-classpath output-lines)))

(define (get-paths-to-targets)
  (let ([pom-list (string-split (with-output-to-string (λ () (system "find . -name pom.xml"))))])
    (foldl (λ (next-path current)
             (string-append current ":" (string-replace (string-replace next-path "pom.xml" "target/classes") "./" "${project}/")))
           "" pom-list)))

(define (javac-linter-settings)
  (hash WORKING-DIRECTORY "."
        ARGS (list "-classpath"
                   (filter-path (string-append (get-classpath) (get-paths-to-targets)))
                   "-Xlint" "-Xlint:-serial")))

(define LINTER-GENERATION-FUNCTION
  (hash 'javac javac-linter-settings
        null null))

;; Dumps debug info at startup
(define (dump-parameters)
  (log (string-append "Generating project settings~n"
                      "  Type: ~a~n"
                      "  Home Directory: ~a~n"
                      "  Current Path: ~a~n"
                      "  Current Directory: ~a~n"
                      "  Output File: ~a~n")
       (project-type) HOME-DIR CURRENT-PATH CURRENT-DIR OUTPUT-FILE))

;; generate-folders-list : string (list of string) ->
(define (generate-folders-list path folder-exclude-patterns)
  (list
    (hash FOLLOW-SYMLINKS #t
          PATH path
          FOLDER-EXCLUDE-PATTERNS folder-exclude-patterns)))

;; Replaces certain path values with the sublime text variable versions.
(define (filter-path path)
  (define filtered-path path)
  ;; This line doesn't work becuase ${home} is only valid in the linter settings.
  ; (set! filtered-path (string-replace filtered-path HOME-DIR "${home}/"))
  (set! filtered-path (string-replace filtered-path CURRENT-DIR "${project_base_name}"))
  (set! filtered-path (string-trim filtered-path "/" #:left? #f))
  filtered-path)

(define (generate-maven-build-systems)
  (define (mvn-cmd cmd-name [name (string-titlecase cmd-name)])
    (hash CMD (list "mvn" "-B" "clean" cmd-name)
          NAME name
          WORKING-DIR (filter-path CURRENT-PATH)))
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
              (hash linter ((hash-ref LINTER-GENERATION-FUNCTION linter)))))
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

(create-project-file)
