#lang racket

(require net/http-client)
(require json)
(require net/uri-codec)

(define users (read-json (open-input-file "./user.json")))

;; Example users.json
;; {
;;    "user": [userID, channelID]
;; }

(define user (car (hash-ref users 'user)))
(define server (cadr (hash-ref users 'user)))

(define (get-avatar)
  (let-values
    ([(status headers in)
      (http-sendrecv
        "discordapp.com"
        (string-append "/api/users/" user)
        #:ssl? #t
        #:method "GET"
        #:headers (list (string-append "authorization: " (getenv "BOT_TOKEN"))))])
    (read-json in)))

(define (send-message)
  (let-values
    ([(status headers in)
      (http-sendrecv
        "discordapp.com"
        (string-append "/api/channels/" server "/messages")
        #:ssl? #t
        #:method "POST"
        #:headers
          (list
            (string-append "authorization: " (getenv "BOT_TOKEN"))
            "Content-Type: application/x-www-form-urlencoded")
        #:data
          (alist->form-urlencoded
            (list (cons 'content "hey nice pic btw")
                  (cons 'tts "false"))))])
    (bytes=? status #"HTTP/1.1 200 OK")))

(define avatar
  (let ([current ""])
    (lambda (x)
      (cond
        [(string=? current x) #t]
        [else
         (begin
           (set! current x)
           #f)]))))

(avatar (hash-ref (get-avatar) 'avatar '()))

(define (main)
  (cond [(avatar (hash-ref (get-avatar) 'avatar '()))
         (begin
           (sleep 2)
           (main))]
        [(send-message) (main)]
        [else 'ERROR]))

(main)
