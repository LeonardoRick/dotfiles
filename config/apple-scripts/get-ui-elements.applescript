tell application "System Events"
	tell process "Microsoft OneNote"
		-- List all UI elements in the front window
		set uiElements to entire contents of window 1
		return uiElements
	end tell
end tell
