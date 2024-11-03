property fontSize : load script POSIX file "/Users/leonardorick/.dotfiles/config/apple-scripts/one-note/change-font-size.scpt"

tell application "Microsoft OneNote"
    activate
end tell

delay 0.5 -- Wait for OneNote to activate

tell fontSize
    changeFontSize(-2)
end tell

