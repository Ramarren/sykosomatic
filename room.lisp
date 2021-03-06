;; Copyright 2008 Josh Marchan

;; This file is part of sykosomatic

;; sykosomatic is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; sykosomatic is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with sykosomatic.  If not, see <http://www.gnu.org/licenses/>.

;; room.lisp
;;
;; Contains the <room> and <door> classes. Also holds functions that handle room generation from
;; file, saving/loading of rooms, setting of exits, getting of information about contents of room
;; (like who the players are within the room), and getting the location of an <entity>
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(in-package :sykosomatic)

;;;
;;; Room vars
;;;

(defvar *rooms* nil
  "List of available rooms. Rooms are also linked as a graph.")

(defvar *max-room-id* 0
  "Highest available room-id")

;;;
;;; Room-related classes
;;;

(defclass <room> (<game-object>)
  ((contents
    :initarg :contents
    :initform nil
    :accessor contents
    :documentation "All contents of this room, including entities")
   (room-id
    :initform (incf *max-room-id*)
    :reader room-id
    :documentation "Universal room ID number")
   (exits
    :initarg :exits
    :initform nil
    :accessor exits
    :documentation "Contains an assoc list of <exit> objects that refer to the next room.")))

(defun make-room (&key (name "NoRoomName") (desc "") (desc-long "") features)
  "Simple constructor function for creating a room."
  (make-instance '<room> 
		 :name name :desc desc 
		 :desc-long desc-long :features features))

(defclass <door> (<game-object>)
  ((open-p
    :initarg :open-p
    :initform t
    :accessor open-p
    :documentation "Is this exit open or closed?")
   (locked-p
    :initarg :locked-p
    :initform nil
    :accessor locked-p
    :documentation "Is the exit locked?")
   (next-room
    :initarg :next-room
    :initform nil
    :accessor next-room
    :documentation "Room object this exit points to")))

(defun make-door (&key (name "door") (desc "") (desc-long "") features next-room)
  "Standard constructor for <door> objects."
  (make-instance '<door> 
		 :name name :desc desc :desc-long desc-long 
		 :features features :next-room next-room))

;;;
;;; Room generation
;;;

(defun make-rooms-from-file (file)
  "Generates rooms from a raw text FILE. Returns a list with all the generated rooms."
  (let ((rooms (with-open-file (in file)
		  (loop for line = (read in nil)
		     while line
		     collect line))))
    (mapcar #'eval rooms)))

;;;
;;; Info
;;;

; functions that grab info specifically about a room go here.

;;;
;;; Room manipulation
;;;

;; NOTE: There should be something like a reflexive set-exit.
(defun set-exit (from-room to-room direction)
  ;;FIXME: This is still doing too much.
  "Checks if there is already an EXIT in DIRECTION, then creates an exit leading to TO-ROOM."
  (if (assoc direction (exits from-room) :test #'string-equal)
      (error "Room already exists in that direction.")
      (let ((door (make-door :next-room to-room)))
	(pushnew (cons direction door) (exits from-room)))))

;;;
;;; Load/Save
;;;

;;; Saving

(defmethod obj->file ((room <room>) path)
  (cl-store:store room (ensure-directories-exist
			(merge-pathnames
			 (format nil "room-~a.room" (room-id room))
			 path))))

(defun save-rooms ()
  "Saves all rooms in *rooms* to individual files in *rooms-directory*"
  (obj-list->files-in-dir *rooms* *rooms-directory*))

;;; Loading

(defun restore-max-room-id ()
  "Loads the highest room-id. Uses existing rooms to find it."
  (setf *max-room-id*
	(apply #'max
	       (mapcar #'room-id *rooms*))))

(defun load-rooms ()
  "Loads saved rooms into the *rooms* list."
  (setf *rooms* (files-in-path->obj-list *rooms-directory* "room"))
  (restore-max-room-id))

;;; Testing

(defun new-test-room ()
  "Returns a new ROOM with its room-id in its name."
  (let ((room (make-room)))
    (setf (name room) (format nil "Room #~a" (room-id room)))
    room))

(defun reset-max-room-id ()
  "Sets the highest room-id to 0."
  (setf *max-room-id* 0))

(defun generate-test-rooms (num-rooms)
  "Returns a LIST containing NUM-ROOMS generic instances of <room>."
  (loop
     for i upto (1- num-rooms)
     collect (new-room)))
