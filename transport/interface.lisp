(in-package #:cl-user)
(defpackage #:jsonrpc/transport/interface
  (:use #:cl)
  (:import-from #:jsonrpc/connection
                #:process-request
                #:add-message-to-queue
                #:connection-request-queue
                #:connection-outbox)
  (:import-from #:bordeaux-threads)
  (:import-from #:event-emitter
                #:event-emitter)
  (:import-from #:chanl)
  (:export #:transport
           #:transport-message-callback
           #:transport-connection
           #:transport-threads
           #:start-server
           #:start-client
           #:send-message-using-transport
           #:receive-message-using-transport
           #:run-processing-loop
           #:run-reading-loop))
(in-package #:jsonrpc/transport/interface)

(defclass transport (event-emitter)
  ((message-callback :initarg :message-callback
                     :accessor transport-message-callback)
   (connection :accessor transport-connection)
   (threads :initform '()
            :accessor transport-threads)))

(defgeneric start-server (transport))

(defgeneric start-client (transport))

(defgeneric send-message-using-transport (transport to message))

(defgeneric receive-message-using-transport (transport from))

(defgeneric run-processing-loop (transport connection)
  (:method ((transport transport) connection)
    (loop
      (chanl:select
        ((chanl:recv (connection-request-queue connection) request)
         (let ((response (process-request connection request)))
           (when response
             (send-message-using-transport transport connection response))))
        ((chanl:recv (connection-outbox connection) message)
         (send-message-using-transport transport connection message))))))

(defgeneric run-reading-loop (transport connection)
  (:method ((transport transport) connection)
    (loop for message = (receive-message-using-transport transport connection)
          while message
          do (add-message-to-queue connection message))))
