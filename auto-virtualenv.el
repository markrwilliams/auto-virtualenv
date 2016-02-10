;;; auto-virtualenv.el --- Auto activate python virtualenvs

;; Copyright (C) 2016 Marcwebbie

;; Author: Marcwebbie <marcwebbie@gmail.com>
;; URL: http://github.com/marcwebbie/auto-virtualenv.el
;; Version: 1.0
;; Keywords: Python, Virtualenv, Tools
;; Package-Requires: ((cl-lib "0.5") (pyvenv "1.9") (s "1.10.0"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Auto virtualenv activates virtualenv automatically when called.
;; To use auto-virtualenv set hooks for `auto-virtualenv-set-virtualenv'

;; For example:
;; (require 'auto-virtualenv)
;; (add-hook 'python-mode-hook 'auto-virtualenv-set-virtualenv)
;; (add-hook 'projectile-after-switch-project-hook 'auto-virtualenv-set-virtualenv)

;;; Code:

(require 'cl-lib)
(require 'python)
(require 'pyvenv)
(require 's)

(defun auto-virtualenv-first-file-exists-p (filelist)
  (let ((filename (expand-file-name (car filelist))))
   (if (file-exists-p filename) filename (first-file-exists-p (cdr filelist)))))

(defcustom auto-virtualenv-dir (auto-virtualenv-first-file-exists-p '("~/.virtualenvs" "~/.pyenv/versions"))
  "The intended virtualenvs installation directory."
  :type 'directory
  :safe #'stringp
  :group 'auto-virtualenv)

(defvar auto-virtualenv-project-roots
  '(".git" ".hg" "Rakefile" "Makefile" "README" "build.xml" ".emacs-project" "Gemfile" ".projectile" "manage.py")
  "The presence of any file/directory in this list indicates a project root.")

(defvar auto-virtualenv--project-root nil
  "Used internally to cache the project root.")
(make-variable-buffer-local 'auto-virtualenv--project-root)

(defvar auto-virtualenv--versions nil
  "Used internally to cache virtualenv versions.")
(make-variable-buffer-local 'auto-virtualenv--versions)

(defun auto-virtualenv--project-root ()
  "Return the current project root directory."
  (or auto-virtualenv--project-root
      (setq auto-virtualenv--project-root
            (expand-file-name
             (or (locate-dominating-file default-directory
                                     (lambda (dir)
                                       (cl-intersection
                                        auto-virtualenv-project-roots
                                        (directory-files dir)
                                        :test 'string-equal))) "")))))
(defun auto-virtualenv--project-name ()
  "Return the project project root name"
  (file-name-nondirectory
   (directory-file-name
    (file-name-directory (auto-virtualenv--project-root)))))

(defun auto-virtualenv--versions ()
  "Get list of available virtualenv names"
  (or auto-virtualenv--versions
      (setq auto-virtualenv--versions
            (directory-files (expand-file-name auto-virtualenv-dir)))))

(defun auto-virtualenv-find-virtualenv-name ()
  "Get current buffer-file possible virtualenv name.
It will try name from .python-version file if it exists or
It will find a virtualenv with the same name of Project Root.
Project root name is found using `auto-virtualenv--project-root'"
  (let ((python-version-file (expand-file-name ".python-version" (auto-virtualenv--project-root))))
    (cond ((file-exists-p python-version-file)
           (with-temp-buffer (insert-file-contents python-version-file) (s-trim (buffer-string))))
          ((member (auto-virtualenv--project-name) (auto-virtualenv--versions))
           (auto-virtualenv--project-name)))))

(defun auto-virtualenv-find-virtualenv-path ()
  "Find path to virtualenv name"
  (when (auto-virtualenv-find-virtualenv-name)
    (expand-file-name (auto-virtualenv-find-virtualenv-name) auto-virtualenv-dir)))

;;;###autoload
(defun auto-virtualenv-set-virtualenv ()
  "Activate virtualenv for buffer-filename"
  (let ((virtualenv-path (auto-virtualenv-find-virtualenv-path)))
    (when (and virtualenv-path (not (equal pyvenv-virtual-env-name (auto-virtualenv--project-name))))
      (message "activated virtualenv: %s" virtualenv-path)
      (pyvenv-mode t)
      (pyvenv-activate virtualenv-path))))

(provide 'auto-virtualenv)

;;; auto-virtualenv.el ends here
