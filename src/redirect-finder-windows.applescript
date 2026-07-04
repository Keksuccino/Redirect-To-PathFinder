property ignoredWindowIds : {}
property handledWindowIds : {}
property redirectAllNewFinderWindows : true
property pollIntervalSeconds : 0.35
property desktopPath : ""
property trashPath : ""
property trashWindowNames : {}
property pathFinderBundleId : "com.cocoatech.PathFinder"

on run
    set desktopPath to POSIX path of (path to desktop folder)
    set trashPath to my currentTrashPath()
    set trashWindowNames to my currentTrashWindowNames()
    set ignoredWindowIds to my currentFinderWindowIds()

    repeat
        my redirectNewFinderWindows()
        delay pollIntervalSeconds
    end repeat
end run

on currentFinderWindowIds()
    set windowIds to {}

    try
        tell application "Finder"
            repeat with finderWindow in windows
                try
                    set end of windowIds to id of finderWindow
                end try
            end repeat
        end tell
    end try

    return windowIds
end currentFinderWindowIds

on redirectNewFinderWindows()
    set finderWindows to {}

    try
        tell application "Finder"
            set finderWindows to windows
        end tell
    on error
        return
    end try

    repeat with finderWindow in finderWindows
        try
            set windowId to missing value
            set windowName to ""
            set targetPath to ""
            set finderBounds to {}

            tell application "Finder"
                try
                    set windowId to id of finderWindow
                end try
                try
                    set windowName to name of finderWindow
                end try
                try
                    set targetPath to POSIX path of (target of finderWindow as alias)
                end try
                try
                    set finderBounds to bounds of finderWindow
                end try
            end tell

            if my shouldHandleWindow(windowId, windowName, targetPath) then
                set end of handledWindowIds to windowId

                tell application "Finder"
                    close finderWindow
                end tell

                my openInPathFinder(targetPath, finderBounds)
            end if
        end try
    end repeat

    my trimHandledWindowIds()
end redirectNewFinderWindows

on shouldHandleWindow(windowId, windowName, targetPath)
    if windowId is missing value then return false
    if ignoredWindowIds contains windowId then return false
    if handledWindowIds contains windowId then return false
    if my isTrashWindow(windowName, targetPath) then return false
    if targetPath is "" then return false

    -- Desktop symlinks often resolve to a target outside ~/Desktop, so the
    -- default mode redirects all new Finder folder windows.
    if redirectAllNewFinderWindows then return true

    return targetPath starts with desktopPath
end shouldHandleWindow

on isTrashWindow(windowName, targetPath)
    if trashWindowNames contains windowName then return true
    if trashPath is not "" and targetPath is trashPath then return true

    return false
end isTrashWindow

on currentTrashPath()
    try
        tell application "Finder"
            return POSIX path of (trash as alias)
        end tell
    end try

    return ""
end currentTrashPath

on currentTrashWindowNames()
    set namesToSkip to {"Trash", "Papierkorb"}

    try
        tell application "Finder"
            set localizedTrashName to localized string "Trash"
        end tell

        if namesToSkip does not contain localizedTrashName then set end of namesToSkip to localizedTrashName
    end try

    return namesToSkip
end currentTrashWindowNames

on openInPathFinder(targetPath, targetBounds)
    do shell script "/usr/bin/open -b " & quoted form of pathFinderBundleId & " " & quoted form of targetPath
    my applyPathFinderBounds(targetBounds)
end openInPathFinder

on applyPathFinderBounds(targetBounds)
    if targetBounds is {} then return false

    repeat 20 times
        try
            tell application "Path Finder"
                activate
                if (count of windows) > 0 then
                    set bounds of window 1 to targetBounds
                    return true
                end if
            end tell
        end try

        delay 0.05
    end repeat

    return false
end applyPathFinderBounds

on trimHandledWindowIds()
    if (count of handledWindowIds) <= 100 then return
    set handledWindowIds to items -50 thru -1 of handledWindowIds
end trimHandledWindowIds
