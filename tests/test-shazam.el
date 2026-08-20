;;; tests-shazam.el --- Now-Playing Tests -*- lexical-binding: t; -*-

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

(require 'shazam-test-utils)

(ert-deftest test-shazam-scrub-json-value ()
  "Test for `shazam-scrub-json-value'."

  (let ((control (shazamt-base-obj))
        (obj (shazamt-shortcut-result)))
    (mapc (lambda (key)
            (shazam-scrub-json-value obj key)
            (should (and (not (map-elt obj key))
                         (not (map-elt control key)))))
          shazamt-keys)))

(ert-deftest test-shazam--render-result ()
  "Test for `shazam--render-result'."

  (let* ((appleid "992558860")
         (artist "Torch Song")
         (title "Raphael")
         (video-url nil)
         (apple-url "https://music.apple.com/us/album/raphael/992558661?i=992558860&itscg=30201&itsct=Shazam_shortcuts")
         (shazam-url nil)
         (lyrics nil)
         (created "2026-08-20 Thu 12:05 PDT")

         (obj (shazamt-base-obj appleid
                                artist
                                title
                                video-url
                                apple-url
                                shazam-url
                                lyrics
                                created))

         (result (shazam--render-result obj))

         (control "* Raphael
:PROPERTIES:
:ARTIST: Torch Song
:CREATED: 2026-08-20 Thu 12:05 PDT
:APPLEID: 992558860
:END:
- [[https://music.apple.com/us/album/raphael/992558661?i=992558860&itscg=30201&itsct=Shazam_shortcuts][Apple Music]]"))

    (should (string-equal control result))))



(provide 'tests-shazam)
;;; tests-shazam.el ends here
