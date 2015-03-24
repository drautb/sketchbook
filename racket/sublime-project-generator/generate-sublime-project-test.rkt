#lang racket

(require rackunit
         "generate-sublime-project.rkt")

;; strip-trailing-slash
(test-case
  "strip-trailing-slash should remove a trailing slash if one exists"
  (check-equal? (strip-trailing-slash "/blah/blah/") "/blah/blah"))

(test-case
  "strip-trailing-slash should leave a string alone if it doesn't have a trailing slash"
  (check-equal? (strip-trailing-slash "/blah/blah") "/blah/blah"))

;; extract-classpath-lines
(test-case
  "extract-classpath-lines should return an empty string when no dependencies could be found"
  (let ([output (string-append "[INFO] No dependencies found.\n"
                               "[INFO] Dependencies classpath:\n"
                               "\n"
                               "[INFO]\n")])
    (check-equal? (extract-classpath-lines output)
                  (list ""))))

(test-case
  "extract-classpath-lines should return each classpath as an element in the list"
  (let ([output (string-append "[INFO] --- maven-dependency-plugin:2.4:build-classpath (default-cli) @ paas-sps-s3 ---\n"
                               "[INFO] No dependencies found.\n"
                               "[INFO] Dependencies classpath:\n"
                               "\n"
                               "[INFO]\n"
                               "[INFO] --- maven-dependency-plugin:2.4:build-classpath (default-cli) @ paas-sps-s3-provisioner ---\n"
                               "[INFO] Dependencies classpath:\n"
                               "jar1:jar2\n"
                               "[INFO]\n"
                               "[INFO] --- maven-dependency-plugin:2.9:build-classpath (default-cli) @ paas-sps-s3-acceptance ---\n"
                               "[INFO] Dependencies classpath:\n"
                               "jar1:jar2\n"
                               "[INFO] ------------------------------------------------------------------------\n"
                               "[INFO] Reactor Summary:\n"
                               "[INFO] BUILD SUCCESS\n")])
    (check-equal? (extract-classpath-lines output)
                  (list "" "jar1:jar2" "jar1:jar2"))))



;; assemble-complete-classpath
(test-case
  "assemble-complete-classpath should return a single classpath containing all the inputs"
  (let ([classpaths '("" "jar1:jar2" "jar3:jar4")])
    (check-equal? (assemble-complete-classpath classpaths)
                  "jar1:jar2:jar3:jar4")))

(test-case
  "assemble-complete-classpath should remove duplicate entries"
  (let ([classpaths '("jar1:jar2:jar3" "jar2:jar3:jar4")])
    (check-equal? (assemble-complete-classpath classpaths)
                  "jar1:jar2:jar3:jar4")))


;; convert-paths-to-classpaths
(test-case
  "convert-paths-to-classpaths should properly convert paths to classpaths"
  (let ([output "./pom.xml"])
    (check-equal? (convert-paths-to-classpaths output)
                  "${project}/target/classes")))

(test-case
  "convert-paths-to-classpaths should concatenate entries with :"
  (let ([output (string-append "./pom.xml\n"
                               "./provisioner/pom.xml\n"
                               "./acceptance/pom.xml\n")])
    (check-equal? (convert-paths-to-classpaths output)
                  "${project}/target/classes:${project}/provisioner/target/classes:${project}/acceptance/target/classes")))


;; javac-linter-settings
(test-case
  "javac-linter-settings should properly generate a hash of settings using the given classpath"
  (let ([classpath "jar1:jar2"])
    (check-equal? (javac-linter-settings classpath)
                   #hash((working_directory . ".")
                         (args . ("-classpath" "jar1:jar2" "-Xlint" "-Xlint:-serial"))))))


;; generate-folders-list
(test-case
  "generate-folders-list should properly generate a list of folder settings"
  (let ([path "."]
        [folder-exclude-patterns '("target")])
    (check-equal? (generate-folders-list path folder-exclude-patterns)
                  (list #hash((path . ".")
                              (follow_symlinks . #t)
                              (folder_exclude_patterns . ("target")))))))



