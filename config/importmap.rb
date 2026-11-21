# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "typing", to: "typing.js"
pin "writing", to: "writing.js"
pin "handwriting", to: "handwriting.js"
pin "practice_run", to: "practice_run.js"
pin "recall", to: "recall.js"
pin "confirm_dialog", to: "confirm_dialog.js"
