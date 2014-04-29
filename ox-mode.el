;;; ox-mode.el
;; Author:   Ox-mode portions: John Zedlewski (2006)
;;          (based almost entirely on derived-mode-ex.el
;;           2002 Martin Stjernholm)
;; Maintainer: John Zedlewski, Joe Bloggs 
;; Created:    October 2002 (derived-mode), July 2006 (ox-mode)
;; Version:    0.4.1 (29/04/2014)
;; Keywords:   c languages oop

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;; 
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;; 
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:
;;
;; Basic mode for Ox programming language derived from derived-mode-ex.el
;; Also modes for batch and algebra files.
;;
;; Note: The interface used in this file requires CC Mode 5.30 or
;; later.

;;; Change log:
;;	
;; 29/04/2014 - Joe Bloggs
;;      * Added more accurate `ox-font-lock-keywords-3'.
;;      * Added ox-batch-mode (for .fl and .alg files)
;; 


;;; Code:

(require 'cc-mode)

;; These are only required at compile time to get the sources for the
;; language constants.  (The cc-fonts require and the font-lock
;; related constants could additionally be put inside an
;; (eval-after-load "font-lock" ...) but then some trickery is
;; necessary to get them compiled.)
(eval-when-compile
  (require 'cc-langs)
  (require 'cc-fonts))

(eval-and-compile
  ;; Make our mode known to the language constant system.  Use Java
  ;; mode as the fallback for the constants we don't change here.
  ;; This needs to be done also at compile time since the language
  ;; constants are evaluated then.
  (c-add-language 'ox-mode 'c++-mode))

;; Ox adds decl keyword (don't bother deleting unnecessary C++ keywords)
(c-lang-defconst c-primitive-type-kwds
  ox (append '("decl")))


;; Support the #import preprocessor directive
(c-lang-defconst c-cpp-matchers
  ox (cons
      ;; Use the eval form for `font-lock-keywords' to be able to use
      ;; the `c-preprocessor-face-name' variable that maps to a
      ;; suitable face depending on the (X)Emacs version.
      '(eval . (list "^\\s *\\(#import\\)\\>\\(.*\\)"
		     (list 1 c-preprocessor-face-name)
		     '(2 font-lock-string-face)))
      ;; There are some other things in `c-cpp-matchers' besides the
      ;; preprocessor support, so include it.
      (c-lang-const c-cpp-matchers)))

;; should work if oxl is in the path
(defgroup ox nil "Ox mode customization")

(defcustom ox-binary-path "oxl" "Command to run oxl" :group 'ox)

(defcustom ox-run-through-shell nil "If non-nil, oxl is run through system shell (allows use of system environment variables)" :group 'ox)

(defcustom ox-use-imenu t "Non-nil to include ox function menu" :group 'ox)

(defcustom ox-font-lock-extra-types nil
  "*List of extra types (aside from the type keywords) to recognize in Ox mode.
Each list item should be a regexp matching a single identifier." :group 'ox)

(defconst ox-font-lock-keywords-1 (c-lang-const c-matchers-1 ox)
  "Minimal highlighting for Ox mode.")

(defconst ox-font-lock-keywords-2 (c-lang-const c-matchers-2 ox)
  "Fast normal highlighting for Ox mode.")

(defconst ox-font-lock-keywords-3
  (list
   ;; control statements
   '("\\<\\(?:algebra\\|break\\|co\\(?:int\\(?:\\(?:commo\\|know\\)n\\)\\|nstraints\\)\\|dynamics\\|exit\\|model\\|nonlinear\\|pr\\(?:intdate\\|ogress\\)\\|s\\(?:amplemean\\|how\\|ystem\\)\\|test\\(?:genres\\|linres\\|res\\|summary\\)\\)\\>" . font-lock-keyword-face)
   ;; model functions
   '("\\<\\(?:AR\\(?:\\(?:FI\\)?MA\\)\\|Gmm\\(?:Level\\)?\\|a\\(?:dftest\\|pp\\(?:enddata\\|results\\)\\|rorder\\)\\|c\\(?:hdir\\|losedata\\|ommand\\)\\|d\\(?:atabase\\|raw[fxz]?\\)\\|estimate\\|f\\(?:ix\\(?:AR\\|MA\\|mean\\)\\|orecast\\)\\|load\\(?:algebra\\|batch\\|command\\|data\\|graph\\)\\|module\\|o\\(?:ption\\|utput\\)\\|p\\(?:ackage\\|rint\\(?:ln\\)?\\)\\|rank\\|s\\(?:ave\\(?:d\\(?:ata\\|rawwindow\\)\\|results\\)\\|et\\(?:d\\(?:raw\\(?:window\\)?\\|ummy\\)\\|t\\(?:est\\|ransform\\)\\)\\|tore\\)\\|test\\|usedata\\)\\>" . font-lock-function-name-face)
   ;; algebra functions
   '("\\<\\(?:_sort\\(?:\\(?:all\\)?by\\)\\|a\\(?:bs\\|c\\(?:f\\|os\\)\\|\\(?:lmo\\|si\\|ta\\)n\\)\\|c\\(?:eil\\|os\\|um\\)\\|d\\(?:a\\(?:te\\|y\\(?:ofweek\\)?\\)\\|e\\(?:lete\\|ns\\(?:chi\\|[fnt]\\)\\)\\|i\\(?:ff\\|v\\)\\|log\\|ummy\\(?:dates\\)?\\)\\|e\\(?:wm\\(?:a\\|c0\\)\\|xp\\)\\|f\\(?:abs\\|loor\\|mod\\)\\|hours\\|i\\(?:n\\(?:dates\\|sample\\)\\|s\\(?:dayofmonth\\|easter\\)\\)\\|l\\(?:ag\\|og\\(?:10\\|gamma\\)?\\)\\|m\\(?:a\\(?:ke\\(?:\\(?:dat\\|tim\\)e\\)\\|x\\)\\|ean\\|in\\(?:utes\\)?\\|o\\(?:nth\\|ving\\(?:SD\\|avg\\)\\)\\)\\|p\\(?:acf\\|e\\(?:ak\\|riod\\(?:ogram\\)?\\)\\|robn\\)\\|quan\\(?:chi\\|[fnt]\\)\\|r\\(?:an\\(?:chi\\|seed\\|[fntu]\\)\\|ound\\)\\|s\\(?:e\\(?:ason\\|conds\\)\\|in\\|mooth_\\(?:[hns]p\\)\\|ort\\|qrt\\|tockv?\\)\\|t\\(?:a\\(?:il\\(?:chi\\|[fnt]\\)\\|n\\)\\|ime\\|r\\(?:end\\|ough\\)\\)\\|variance\\|year\\)\\>" . font-lock-function-name-face))
   "Accurate normal highlighting for oxmetrics modes.")

(defvar ox-font-lock-keywords ox-font-lock-keywords-3
  "Default expressions to highlight in Ox mode.")

(defvar ox-mode-syntax-table nil
  "Syntax table used in ox-mode buffers.")
(or ox-mode-syntax-table
    (setq ox-mode-syntax-table
	  (funcall (c-lang-const c-make-mode-syntax-table ox))))

(defvar ox-mode-abbrev-table nil
  "Abbreviation table used in ox-mode buffers.")
(c-define-abbrev-table 'ox-mode-abbrev-table
  ;; Keywords that if they occur first on a line might alter the
  ;; syntactic context, and which therefore should trig reindentation
  ;; when they are completed.
  '(("else" "else" c-electric-continued-statement 0)
    ("while" "while" c-electric-continued-statement 0)))

(defun ox-run-noshell ()
  (interactive)
  (compile
   (concat ox-binary-path " \"" (buffer-file-name) "\"")
   )  
  )

(defun ox-run-withshell ()
  (shell-command 
   (concat ox-binary-path " " (buffer-file-name)) "*Ox output*" "*Ox errors*")  
  )

(defun ox-run ()
  "Executes the current buffer with oxl"
  (interactive)
  (if ox-run-through-shell
      (ox-run-withshell)
    (ox-run-noshell)
      )
  )

(defun ox-parse ()
  "Parses the current buffer, but doesn't run it, with oxl"
  (interactive)
  (compile
   (concat ox-binary-path " -r- " (buffer-file-name))
   )
  )


(defvar ox-mode-map ()
  "Keymap used in ox-mode buffers.")

;; Set up mode-specific key bindings
(if ox-mode-map nil
  (setq ox-mode-map (c-make-inherited-keymap))
  (define-key ox-mode-map "\C-co" 'ox-run)
  (define-key ox-mode-map "\C-cp" 'ox-parse)

;; Debugging commands (optional keybindings)
;; (I'll straighten out these keybindings when we upgrade debugging
;; support next)
;  (define-key ox-mode-map "\C-M-r" 'ox-debug-next)
;  (define-key ox-mode-map "\C-M-down" 'ox-debug-step-over)
;  (define-key ox-mode-map "\C-M-up" 'ox-debug-step-out)
;  (define-key ox-mode-map "\C-M-end" 'ox-debug-quit)
  (define-key ox-mode-map "\C-cg" 'ox-debug-go)
  (define-key ox-mode-map "\C-cd" 'ox-debug)

;; Menu commands  
  (define-key ox-mode-map [menu-bar ox-menu oxrun]
    '("Run buffer with ox" . ox-run))
  )


;; Use the c-mode menu, plus a few additions
(easy-menu-define ox-menu ox-mode-map "Ox Mode Commands"
  (cons "Ox"
	(nconc
	 (c-lang-const c-mode-menu ox)
	 '(
	   "---"
	   [ "Run with ox" ox-run t ]
	   [ "Parse only with ox" ox-parse t ]
	   ;; add ox-only menu items here
	   )
	 )))

;; provides a drop-down list of ox functions in the current buffer
;; you must use something close to the "standard ox" indentation system
;; for this to work (function name on one line, open brace at beginning of
;; next line)
(defun ox-setup-imenu ()
  (setq imenu-generic-expression
	'((nil "^[[:space:]]*\\(static\\)?[[:space:]]*\\([[:word:]:]+\\)[ ]*(.*)[ \n]*\n{"  2)
	  ("Classes" "^[[:space:]]*class[[:space:]]*\\([[:word:]]+\\)[[:space:]]+" 1)
	  ))
  (imenu-add-to-menubar "OxFunctions"))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.ox\\'" . ox-mode))

;;;###autoload
(defun ox-mode ()
  "Major mode for editing Ox code.
   Based on dervied-mode-ex

The hook `c-mode-common-hook' is run with no args at mode
initialization, then `ox-mode-hook'.

Key bindings:
\\{ox-mode-map}"
  (interactive)
  (kill-all-local-variables)
  (c-initialize-cc-mode t)
  (set-syntax-table ox-mode-syntax-table)
  
  ;; Treat the transpose operator (') as punctuation in ox
  (modify-syntax-entry ?\' "." ox-mode-syntax-table)
  
  (setq major-mode 'ox-mode
	mode-name "Ox"
	local-abbrev-table ox-mode-abbrev-table
	abbrev-mode t)
  (use-local-map ox-mode-map)

  ;; `c-init-language-vars' is a macro that is expanded at compile
  ;; time to a large `setq' with all the language variables and their
  ;; customized values for our language.
  (c-init-language-vars ox-mode)
  ;; `c-common-init' initializes most of the components of a CC Mode
  ;; buffer, including setup of the mode menu, font-lock, etc.
  ;; There's also a lower level routine `c-basic-common-init' that
  ;; only makes the necessary initialization to get the syntactic
  ;; analysis and similar things working.
  (c-common-init 'ox-mode)
  
  (easy-menu-add ox-menu)
  (if ox-use-imenu
      (ox-setup-imenu)
    )
  (run-hooks 'c-mode-common-hook)
  (run-hooks 'ox-mode-hook)
  (c-update-modeline))

;; parse error messages from ox interpreter
(require 'compile)
(setq compilation-error-regexp-alist
      (append '(( "\\(.+\\.ox\\) \(\\([0-9]+\\)\): .*"1 2))
	      compilation-error-regexp-alist))

;; ox-batch-mode and ox-algebra-mode added by Joe Bloggs (Tue Apr 29 00:03:12 2014)
(add-to-list 'auto-mode-alist '("\\.fl\\'" . ox-batch-mode))
(add-to-list 'auto-mode-alist '("\\.alg\\'" . ox-batch-mode))

(defvar ox-batch-mode-map ()
  "Keymap used in ox-mode buffers.")

(if ox-batch-mode-map nil
  (setq ox-batch-mode-map (c-make-inherited-keymap)))

(easy-menu-define ox-batch-menu ox-batch-mode-map "Ox Batch Mode Commands"
  (cons "Ox"
	(nconc
	 (c-lang-const c-mode-menu ox)
         nil)))

(define-derived-mode ox-batch-mode ox-mode "ox-batch-mode"
  "Major-mode for editing oxmetrics batch mode files.
This is derived from `ox-mode'.
\\{ox-batch-mode-map}"
  :syntax-table nil
  :abbrev-table nil
  (set (make-local-variable 'font-lock-defaults) '(ox-font-lock-keywords nil t)))


;;
;; Debugging support
;; Contributed by: Riccardo Jack Lucchetti <r.lucchetti@univpm.it>
;; Note that you need Ox professional for debugging on Windows.
;;

(defun ox-debug-send-command (cmdstr)
  "Send a command to the Ox debugger"
  (interactive ())
  (setq oxfile (current-buffer))
  (switch-to-buffer "Oxl debug")
  (send-invisible cmdstr)
  (sleep-for 0.1)
  (end-of-buffer)
  (search-backward-regexp "^\\(.+\\) (\\([0-9]+\\)): break!")
  (setq lineno (match-string 2))
  (setq fname (match-string 1))
  (message (concat "***" fname "*** -> " lineno))
  (if (string-equal "(debug)" (substring fname 0 7))
      (setq fname (substring fname 7 nil)))
  (switch-to-buffer oxfile)
  (find-file fname)
  (goto-line (string-to-int lineno))
  )


(defun ox-debug-next ()
  "run next command"
  (interactive ())
  (ox-debug-send-command "")
  )

(defun ox-debug-step-over ()
  "run the `#step over' command"
  (interactive ())
  (ox-debug-send-command "#step over")
  )

(defun ox-debug-step-out ()
  "run the `#step out' command"
  (interactive ())
  (ox-debug-send-command "#step out")
  )

(defun ox-debug-quit ()
  "run the `#quit' over command"
  (interactive ())
  (ox-debug-send-command "#quit")
  (ox-debug-send-command "exit")
  (switch-to-buffer "Oxl debug")
  (delete-window)
  (kill-buffer "Oxl debug")
)

(defun ox-debug-go (lineno)
  "run through line n"
  (interactive "sline no (RET for end): ")
  (goto-line (string-to-int lineno))
  (ox-debug-send-command (concat "#go " lineno))
  )

(defun ox-debug ()
  "Debug an ox file interactively"
  (interactive ())
  (goto-line 1)
  (search-forward "main()")
  (search-forward ";")
  (setq oxfile (current-buffer))
  (setq ox-dbg-go "#go ")
  (save-buffer)
  (setq ox-cmd (concat "oxl -d " (buffer-file-name)))
  (shell "Oxl debug") 
  (send-invisible ox-cmd)
  (switch-to-buffer-other-window oxfile)
  )




(provide 'ox-mode)

;;; ox-mode.el ends here
