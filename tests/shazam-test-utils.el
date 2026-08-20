;;; shazam-test-utils.el --- Now Playing Test Utils           -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Charles Choi

;; Author: Charles Choi <kickingvegas@gmail.com>
;; Keywords: tools

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

;;

;;; Code:
(require 'map)
(require 'ert)
(require 'shazam)

(defvar shazamt-keys '("apple music id" "artist" "title"
                       "video URL" "apple music URL" "shazam URL"
                       "lyricsSnippet"
                       "created")
  "Shazam result keys.")

(defun shazamt-base-obj (&optional appleid artist title video-url apple-url shazam-url lyrics created)
  "Create Shazam base object.

- APPLEID - Apple Music ID
- ARTIST - Artist
- TITLE - Title
- VIDEO-URL - Video URL
- APPLE-URL - Apple Music URL
- SHAZAM-URL - Shazam URL
- LYRICS - Lyrics snippet"

  (let ((obj (make-hash-table :test #'equal)))
    (map-put! obj "apple music id" appleid)
    (map-put! obj "artist" artist)
    (map-put! obj "title" title)
    (map-put! obj "video URL" video-url)
    (map-put! obj "apple music URL" apple-url)
    (map-put! obj "shazam URL" shazam-url)
    (map-put! obj "lyricsSnippet" lyrics)
    (map-put! obj "created" created)
    obj))

(defun shazamt-shortcut-result ()
  "Create Shazam result from Shortcut."

  (let ((obj (shazamt-base-obj)))
    (mapc (lambda (key)
            (map-put! obj key ""))
          shazamt-keys)
    obj))



(provide 'shazam-test-utils)
;;; shazam-test-utils.el ends here
