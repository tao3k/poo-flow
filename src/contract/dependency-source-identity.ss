(export #t)

(import :clan/poo/object)

;;; Canonical owner: local package paths and runtime load paths are projections.
(def (dependency-source-entry
      logical-package-value
      repository-name-value
      canonical-uri-value
      revision-value
      sha256-value
      strip-prefix-value)
  (.o (kind 'poo-flow.dependency-source-entry.1)
      (logical-package logical-package-value)
      (repository-name repository-name-value)
      (canonical-uri canonical-uri-value)
      (revision revision-value)
      (sha256 sha256-value)
      (strip-prefix strip-prefix-value)
      (archive-url
       (string-append canonical-uri-value
                      "/archive/"
                      revision-value
                      ".tar.gz"))))

(def +poo-flow-dependency-source-contract+
  (.o (kind 'poo-flow.dependency-source-contract.1)
      (schema "poo-flow.dependency-source-contract.1")
      (version 1)
      (dependencies
       (list
        (dependency-source-entry
         "gerbil-poo"
         "gerbil_poo_sources"
         "https://github.com/mighty-gerbils/gerbil-poo"
         "1c3225637525400341a09e958296962c10184ead"
         "9425b2baff5ee87c046d43dac0b11ed6b174f4e4c12c01c747c066383517964e"
         "gerbil-poo-1c3225637525400341a09e958296962c10184ead")
        (dependency-source-entry
         "gerbil-utils"
         "gerbil_utils_sources"
         "https://github.com/mighty-gerbils/gerbil-utils"
         "f45a4ef3bfecd2af39e114ed736ce9082cbb8244"
         "e7777c505e71de490dc05f8e3ff4473dddbc998a99899c085d31750add551296"
         "gerbil-utils-f45a4ef3bfecd2af39e114ed736ce9082cbb8244")
        (dependency-source-entry
         "gslph"
         "gslph_sources"
         "https://github.com/tao3k/gerbil-scheme-language-project-harness"
         "8eb8604e1907c294c60d8c6a7084c0ab50a80557"
         "6b52760c63368027d24c43c0e01fffa54a915207fd236a45ca878dc7391d0307"
         "gerbil-scheme-language-project-harness-8eb8604e1907c294c60d8c6a7084c0ab50a80557")))))

(def (emit-line port . values)
  (for-each (lambda (value) (display value port)) values)
  (newline port))

(def (emit-source-package port dependency)
  (emit-line port "gerbil_dependency_sources.source_package(")
  (emit-line port "    canonical_uri = \"" (.ref dependency 'canonical-uri) "\",")
  (emit-line port "    name = \"" (.ref dependency 'repository-name) "\",")
  (emit-line port "    package = \"" (.ref dependency 'logical-package) "\",")
  (emit-line port "    revision = \"" (.ref dependency 'revision) "\",")
  (emit-line port "    sha256 = \"" (.ref dependency 'sha256) "\",")
  (emit-line port "    strip_prefix = \"" (.ref dependency 'strip-prefix) "\",")
  (emit-line port "    urls = [")
  (emit-line port "        \"" (.ref dependency 'archive-url) "\",")
  (emit-line port "    ],")
  (emit-line port ")")
  (newline port))

(def (poo-flow-dependency-source-contract->module-fragment contract)
  (let (port (open-output-string))
    (emit-line port "gerbil_dependency_sources = use_extension(")
    (emit-line port "    \"@gerbil_bazel//gerbil:extensions.bzl\",")
    (emit-line port "    \"gerbil\",")
    (emit-line port ")")
    (newline port)
    (for-each
     (lambda (dependency)
       (emit-source-package port dependency))
     (.ref contract 'dependencies))
    (emit-line port "use_repo(")
    (emit-line port "    gerbil_dependency_sources,")
    (for-each
     (lambda (dependency)
       (emit-line port "    \"" (.ref dependency 'repository-name) "\","))
     (.ref contract 'dependencies))
    (emit-line port ")")
    (get-output-string port)))
