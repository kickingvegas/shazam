;;; shazam.el --- Shazam Interface (macOS only)     -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Charles Choi

;; Author: Charles Choi <kickingvegas@gmail.com>
;; URL: https://github.com/kickingvegas/shazam
;; Keywords: tools
;; Version: 0.1.0-rc.2
;; Package-Requires: ((emacs "30.1"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; shazam.el is an Emacs interface to the Shazam music recognition feature in
;; macOS 14.2+ (Sonoma or more recent).

;; INSTALL
;; This package requires the installation of a macOS Shortcut named "Identify
;; Music JSON". Download and install it on your system by clicking on the link
;; below:

;; https://www.icloud.com/shortcuts/bba3dd21146c4ba78dff1d7d0c0b1092

;; shazam.el by default requires your Emacs session to load the macOS SF Symbols
;; font. Use the convenience command `shazam-init' to setup both SF Symbols and
;; to globally set your keybinding preference to the `shazam' command.

;; Add the following line to your Emacs initialization file:

;; (shazam-init "M-<f19>")

;; If no binding is desired, `shazam-init' can be called with no arguments.

;;

;;; Code:
(require 'map)

(defgroup shazam nil
  "Group settings for Shazam."
  :group 'convenience)

(defvar shazam--last-result nil
  "Last search result.")

(defcustom shazam-log-file "~/shazam.org"
  "Log file for Shazam discoveries."
  :type 'file
  :group 'shazam)

(defun shazam-message-shazam-result (shazam)
  "Show message given SHAZAM."
  (let* ((response shazam)
         (title (substring-no-properties (map-elt response "title")))
         (artist (substring-no-properties (map-elt response "artist")))
         (msg (format "%s • %s" title artist)))
    msg))

(defun shazam-scrub-json-value (obj key)
  "Scrub value for KEY in OBJ."
  (let ((value (map-elt obj key)))
    (if (and value (stringp value) (string-equal value ""))
        (map-put! obj key nil)
      (map-put! obj key value))))

(defun shazam-urldecode-value (obj key)
  "Url decode value for KEY in OBJ."
  (let* ((value (map-elt obj key))
         (decoded-value (url-unhex-string value)))
    (decode-coding-string decoded-value 'utf-8)))


(defun shazam--process-filter (_process output)
  "Process filter PROCESS and OUTPUT."
  (if (and output (stringp output))
      (cond
       ((string-match-p "^Error: Shazam didn't recognize any media." output)
        (setq shazam--last-result (format "􁈴 %s" (string-trim output))))

       ((string-match-p "^Error: Running was cancelled" output)
        (setq shazam--last-result (format "􁈴 %s" "Running was cancelled")))

       (t
        (let* ((response (json-parse-string output
                                          :null-object nil)))

        (shazam-scrub-json-value response "apple music id")
        (shazam-scrub-json-value response "artist")
        (shazam-scrub-json-value response "title")
        (shazam-scrub-json-value response "name")
        (shazam-scrub-json-value response "video URL")
        (shazam-scrub-json-value response "apple music URL")
        (shazam-scrub-json-value response "shazam URL")
        (shazam-scrub-json-value response "lyricsSnippet")

        (mapc (lambda (key)
                (let ((value (map-elt response key)))
                  (if (and value (not (string-equal value "")))
                      (map-put! response key
                                (shazam-urldecode-value response key)))))
              '("artist" "title" "lyricsSnippet"))

        (map-put! response "created"
                  (format-time-string "%Y-%m-%d %a %H:%M %Z"))

        (setq shazam--last-result response))))))

(defun shazam--process-sentinel (process signal)
  "Process sentinel for PROCESS and SIGNAL."
  (when (string-match-p "finished\\|exited" signal)
    (let ((exit-code (process-exit-status process)))
      (if (= exit-code 0)
          (cond
           ((stringp shazam--last-result)
            (message shazam--last-result))

           ((hash-table-p shazam--last-result)
            (let ((msg (shazam-message-shazam-result
                        shazam--last-result)))
              (shazam-log-last-result)
              (kill-new msg)
              (message "􁈴 %s" msg)))
           (t
            (error "􁈴 Undefined shazam--last-result")))
        (error "􁈴 exit error")))))

(defun shazam ()
  "Identify music with Shazam.

Runs Shazam shortcut in the background. Resulting output is captured in
the async buffer and `kill-ring'."
  (interactive)
  (let ((proc (start-process "shazam"
                             nil
                             "sh" "-c"
                             "shortcuts run 'Identify Music JSON' | cat")))
    (set-process-filter proc #'shazam--process-filter)
    (set-process-sentinel proc #'shazam--process-sentinel)))

(defun shazam--render-last ()
  "Render last Shazam result."

  (if (not shazam--last-result)
      (error "No Shazam result to show")

    (let* ((obj shazam--last-result)
           (buflist ())
           (created (map-elt obj "created"))
           (music-id (map-elt obj "apple music id"))
           (artist (map-elt obj "artist"))
           (title (map-elt obj "title"))
           (video-url (map-elt obj "video URL"))
           (apple-url (map-elt obj "apple music URL"))
           (shazam-url (map-elt obj "shazam URL"))
           (lyrics (map-elt obj "lyricsSnippet"))

           (buflist (push (format "* %s" title) buflist))
           (buflist (push ":PROPERTIES:" buflist))
           (buflist (if artist
                        (push (format ":ARTIST: %s" artist) buflist)
                      buflist))
           (buflist (if created
                        (push (format ":CREATED: %s" created) buflist)
                      buflist))
           (buflist (if music-id
                        (push (format ":APPLEID: %s" music-id) buflist)
                      buflist))
           (buflist (push ":END:" buflist))

           (buflist (if apple-url
                        (push (format "- [[%s][Apple Music]]" apple-url) buflist)
                      buflist))
           (buflist (if shazam-url
                        (push (format "- [[%s][Shazam]]" shazam-url) buflist)
                      buflist))
           (buflist (if video-url
                        (push (format "- [[%s][Video]]" video-url) buflist)
                      buflist))

           (buflist (if lyrics
                        (progn
                          (push "** Lyrics Snippet" buflist)
                          (push (format "%s" lyrics) buflist))
                      buflist))

           (msg (string-join (reverse buflist) "\n")))

      msg)))

(defun shazam-insert-last-org ()
  "Insert last Shazam result formatted in Org."
  (let ((msg (shazam--render-last)))
    (insert msg)))

(defun shazam-log-last-result ()
  "Log last Shazam result."
  (save-excursion
    (let* ((cur (current-buffer))
           (buf (find-file shazam-log-file)))
      (with-current-buffer buf
        (goto-char (point-min))
        (shazam-insert-last-org)
        (insert "\n\n")
        (save-buffer))
      (switch-to-buffer cur))))

(defun shazam-find-log ()
  "Open Shazam log file."
  (interactive)
  (find-file shazam-log-file)
  (goto-char (point-min)))

(defun shazam-init (&optional b)
  "Initialize Shazam, binding B to `shazam' if B is non-nil."
  (interactive)
  (if (not (eq system-type 'darwin))
      (error "Only supported on macOS")
    (if (and (display-graphic-p) (fboundp 'set-fontset-font))
        (set-fontset-font t '(?􀀀 . ?􏿽) "SF Pro Display")))

  (if b
      (keymap-global-set b #'shazam)))

(provide 'shazam)
;;; shazam.el ends here
