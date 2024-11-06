tell application "Microsoft OneNote"
    activate
end tell

delay 0.5 -- Wait for OneNote to activate

-- ? --------------------------------------------------------------------------------------------------------------
-- ? ---- copy from this line below  as the script to run with some shortcut when OneNote is already activated ----
-- ? --------------------------------------------------------------------------------------------------------------
on changeFontSize(size)
    tell application "System Events"
        tell (first process whose frontmost is true)
            -- Check if the "Home" tab is selected
            set home to radio button "Home" of tab group 1 of window 1

            -- Convert the value to a boolean
            set isTabSelected to (value of home is not 0)

            -- Display dialog with the selection status
            if not isTabSelected then
                click home
                delay 0.1
            end if

            -- Focus on the combo box
            set focusedElement to combo box 2 of group 2 of scroll area 1 of tab group 1 of window 1
            set focused of focusedElement to true

            set initialValue to value of focusedElement

            if initialValue is "" or initialValue is missing value then
                set clipboardValue to the clipboard
                try
                    set initialValue to clipboardValue as number
                on error
                    set initialValue to 11
                end try
            end if

            -- Retrieve input value, increase it by 2, and update clipboard
            set newValue to initialValue + size
            keystroke newValue
            set the clipboard to (newValue as text)
        end tell
    end tell
end changeFontSize


changeFontSize(1)

