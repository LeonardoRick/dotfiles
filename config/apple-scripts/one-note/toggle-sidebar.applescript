tell application "Microsoft OneNote"
    activate
end tell

delay 0.5 -- Wait for OneNote to activate

-- ? -----------------------------------------------------------------------------
-- ? ---- copy from this line below  as the script to run with some showrtcut ----
-- ? -----------------------------------------------------------------------------
tell application "System Events"
    tell process "Microsoft OneNote"
        set booksButton to checkbox 1 of group 1 of splitter group 1 of window 1
        click booksButton
    end tell
end tell
