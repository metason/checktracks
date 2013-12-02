--
--  AppDelegate.applescript
--  CheckTracks
--
--  Created by Philipp Ackermann on 1/23/13.
--  Copyright (c) 2013 Philipp Ackermann. All rights reserved.
--

-- TODO
-- - Umsortierung der New Tracks in TabelView ermöglichen!
-- - remove the timeout blocks, iTunes > 11.1.3 seems to be o.k. (no more blocking)
-- - add audio fingerprinting --> Bernard's idea
-- - GUI builder: flexile constrains? alb & albart textfield dep.
-- - Exclude booklets when checking for disc cnt warning
-- - BestFit... in search meta
-- - Tooltips
-- - Internationalization
-- - Help & About
-- - app sandbox, code signing, build process, temp dir access?
-- - improve error handling
-- - split script source files (with import?) / reuse in other project?
-- - Docu der service calls and JSON results
-- - Hourglass cursor

script AppDelegate
	property parent : class "NSObject"
	-- Data
    property selTracks : missing value
    property noOfselTracks : 0
    property deadTracks : missing value
    property noOfdeadTracks : 0
    property numTracks : missing value
    property noOfnumTracks : 0
    property prefixDigits : 0
    property duplTracks : missing value -- duplicated tracks to delete
    property alb : missing value
    property sameAlbum : false
    property art : missing value
    property sameArtist : false
    property albart : missing value
    property releaseYear : missing value
    property albGenre : missing value
    property discNo : missing value
    property sameDiscNo : false
    property discCount : missing value
    property sameDiscCount : false
    property isCompilation : false
    property tempComment : missing value -- temporay comment of current track
    property sameComment : false
    property totalTracks : missing value
    property sortArt : missing value
    property sortAlbArt : missing value
    property sortAlb : missing value
    property sortTags : false
    property coverURL : missing value
    property coverExists : missing value
    property tempDir : missing value
    property albumData : missing value -- records with key, oldval, newval
    property albumController : missing value -- connected in the .xib file
    property tracksData : missing value -- current tracks as record list
    property tracksController : missing value -- connected in the .xib file
    property newtracksData : missing value -- new tracks as TrackInfo list
    property newtracksController : missing value -- connected in the .xib file
    property albumsList : missing value -- AlbumInfo list
    property albumsListController : missing value -- connected in the .xib file
    
    property iTListener : 0 -- listens to iTunes notifications
    property doAutoSync : true -- sync with iTunes; but not when panels are open

    
    -- main GUI elements
    property topLabel : missing value
    property iTunesBox : missing value
    property albumLabel : missing value
    property artistLabel : missing value
    property yearLabel : missing value
    property genreLabel : missing value
    property imgView : missing value
    property imgLabel : missing value
    property imgBox : missing value
    property metaButton : missing value
    property metaBox : missing value
    property coverButton : missing value
    property sortLabel : missing value
    property sortButton : missing value
    property sortBox : missing value
    property discLabel : missing value
    property discNumField : missing value
    property discCntField : missing value
    property discButton : missing value
    property discBox : missing value
    property commentLabel : missing value
    property commentButton : missing value
    property commentBox : missing value
    property missingLabel : missing value
    property missingBox : missing value
    property removeButton : missing value -- for removing missing tracks
    property duplicateLabel : missing value
    property duplicateBox : missing value
    property deleteButton : missing value -- for deleting duplicate tracks
    property numLabel : missing value
    property numBox : missing value
    property checkButton : missing value
    property convertNumButton : missing value
    property digitsField : missing value
    property remPrefixButton : missing value
    -- meta info panel GUI elements
    property metaPanel : missing value
    property mpAlbumLabel : missing value
    property mpArtistLabel : missing value
    property mpAlbumsPopup : missing value -- connected in the .xib file
    property mpAlbumTable : missing value -- connected in the .xib file
    property mpTracksTable : missing value -- connected in the .xib file
    property mpNewTracksTable : missing value -- connected in the .xib file
    property mpSourcePopup : missing value
    property mpIncludeButton : missing value
    property mpIncludeState : missing value
    property mpSetButton : missing value
    -- cover panel GUI elements
    property coverPanel : missing value
    property cpAlbumLabel : missing value
    property cpArtistLabel : missing value
    property cpSourcePopup : missing value
    property cpAlbumsPopup : missing value -- connected in the .xib file
    property coverView : missing value
    property cpImgLabel : missing value
    property cpImg : missing value
    property cpSetButton : missing value
    
    -- debugging
    property logErrors : true
    property logJSON : true
    property logFlow : true

    
    -- constants
    property multiImg : missing value
    property notfoundImg : missing value
    
    -- uppercase characters
    property _ucChars : "AÄÁÀÂÃÅĂĄÆBCÇĆČDĎĐEÉÈÊËĚĘFGHIÍÌÎÏJKLĹĽŁMNÑŃŇ" & ¬
    "OÖÓÒÔÕŐØPQRŔŘSŞŠŚTŤŢUÜÚÙÛŮŰVWXYÝZŽŹŻÞ"

    -- lowercase characters
    property _lcChars : "aäáàâãåăąæbcçćčdďđeéèêëěęfghiíìîïjklĺľłmnñńň" & ¬
    "oöóòôõőøpqrŕřsşšśtťţuüúùûůűvwxyýzžźżþ"
    
    -- These are the words that will remain lowercase, unless they begin the title. -- ? "de", 
    property lowercase_words : {"a", "an", "as", "and", "at", "but", "by", "for", "in", "into", "nor", "of", "on", "or", "so", "the", "to", "with", "vs.", "feat", "von", "van", "o'", "'n'", "n'"}
    
    property unmodified_words : {"II", "III", "IV", "VI", "VII", "VIII", "IX", "XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX", "XXX", "FM", "UKW", "USA", "TV", "MGM", "DVD", "ABC", "CD", "USSR", "CA", "WA", "NY", "NYC", "LP", "EP", "VHS", "UK", "GB", "'Bout", "'Cause"}

    -- helper routines
    -- set warn box: 0=none (transparent); 1= yellow; 2=red
    on warn(box, status)
        if status = 0
            box's setTransparent_(true)
        else
            box's setTransparent_(false)
            if status = 1 then
                box's setFillColor_(current application's NSColor's yellowColor)
            else
                box's setFillColor_(current application's NSColor's redColor)
            end if
        end if
    end warn
    
    on getIntFromString(this_string)
        set len to length of this_string
        set idx to 0
        set index1 to 0
        set index2 to 0
        repeat len times
            set idx to (idx + 1)
            set c to character idx of this_string
            if (c >= "0" and c <= "9") then
                if index1 = 0 then
                    set index1 to idx
                end if
                set index2 to idx
            else
                if not index1 = 0 then
                    exit repeat
                end if
            end if
        end repeat
        if index1 = 0 or index2 = 0 then return 0
        set res to text index1 thru index2 of this_string
        return res as integer
    end getIntFromString
    
    on getIntFromStringEnd(this_string)
        set len to length of this_string
        set idx to len as integer
        set index1 to 1
        set index2 to 0
        repeat len times
            set c to character idx of this_string
            if (c >= "0" and c <= "9") then
                if index2 = 0 then set index2 to idx
                set index1 to idx
            else
                if not index2 = 0 then
                    exit repeat
                end if
            end if
            set idx to (idx - 1)
        end repeat
        if index1 = 0 or index2 = 0 then return 0
        set res to text index1 thru index2 of this_string
        return res as integer
        
    end getIntFromStringEnd
    
    on replace_chars(this_text, search_string, replacement_string)
        set prevTIDs to text item delimiters of AppleScript
        set AppleScript's text item delimiters to the search_string
        set the item_list to every text item of this_text
        set AppleScript's text item delimiters to the replacement_string
        set ret_text to the item_list as string
        set text item delimiters of AppleScript to prevTIDs
        return ret_text
    end replace_chars
    
    on translateChars(theText, fromChars, toChars)
        try
            set newText to ""
            repeat with char in theText
                set newChar to char
                set x to offset of char in fromChars
                if x is not 0 then set newChar to character x of toChars
                set newText to newText & newChar
            end repeat
            return newText
        on error eMsg number eNum
            error "Can't translateChars: " & eMsg number eNum
            return theText -- untranslated
        end try
    end translateChars
    
    on upperString(theText)
        return translateChars(theText, _lcChars, _ucChars)
    end upperString
    
    on lowerString(theText)
        return translateChars(theText, _ucChars, _lcChars)
    end lowerString

    -- Use: capitalizeWordsWithExceptions("hERE comes The Sun.", {"the"})
    -- ---> "Here Comes the Sun."
    on capitalizeWordsWithExceptions(str, exceptionList)
        try
            if length of str = 0 then
                return str
            end if
        on error
            return ""
        end try
        set widx to 0
        set res to ""
        try
            set wordList to words in str
        on error
            if logErrors then log "capitalizeWordsWithExceptions failed."
            return str
        end try
        --log wordList
        -- add leading special characters
        set c to character 1 of item 1 of wordList
        try
            set x to 1
            repeat while not c = character x of str
                set res to res & character x of str
                set x to x + 1
            end repeat
        on error
            return str
        end try
        -- do capitalization
        repeat with currWord in wordList
            if (currWord is in unmodified_words) then
                set lcWord to currWord as string
                set exc to false
            else
                set lcWord to lowerString(currWord as string)
                set exc to lcWord is in exceptionList
                -- handle "McX"
                if length of lcWord > 3 then
                    if (character 1 of lcWord = "m" and character 2 of lcWord = "c") then
                        set c to character 3 of lcWord
                        set x to offset of c in _lcChars
                        if x is not 0 then
                            set mc to "Mc" & character x of _ucChars
                        else
                            set mc to "Mc" & c
                        end if
                        set lcWord to mc & (get text 4 through -1 of lcWord)
                        set exc to false
                    end if
                end if
            end if
            if (widx = 0) then
                set c to character 1 of lcWord
                set x to offset of c in _lcChars
                if x is not 0 then
                    set newWord to character x of _ucChars
                else
                    set newWord to c
                end if
                if length of lcWord > 1 then
                     set newWord to newWord & (get text 2 through -1 of lcWord)                    
                end if
                set res to res & newWord
            else
                if not exc then
                    set c to character 1 of lcWord
                    set x to offset of c in _lcChars
                    if x is not 0 then
                        set newWord to character x of _ucChars
                    else
                        set newWord to c
                    end if
                    if length of lcWord > 1 then
                        set newWord to newWord & (get text 2 through -1 of lcWord)
                    end if
                else
                    set newWord to lcWord
                end if
                -- fill in-betweens
                set x to (length of res) + 1
                set c to character x of str
                repeat while (offset of c in _lcChars) is 0
                    if c >= "0" and c <= "9" then
                        exit repeat
                    end if
                    set res to res & c
                    if length of str = length of res then exit repeat
                    set x to x + 1
                    set c to character x of str
                end repeat
                -- add word
                set res to res & newWord
            end if
            set widx to widx + 1
        end repeat
        -- add missing chars
        try
            repeat while length of str > length of res
                set x to (length of res + 1)
                set res to res & character x of str
            end repeat
        on error
            return res
        end try
        return res
    end capitalizeWordsWithExceptions
    
    on setAlbumMeta(keyAttr, thisVal)
        repeat with currItem in albumData
            if keyAttr equals (attr of currItem) as string then
                set newVal of currItem to thisVal
                if thisVal as string equals (oldVal of currItem) as string then
                    set takeNew of currItem to 0
                else
                    set takeNew of currItem to 1
                end if
                exit repeat
            end if
        end repeat
    end setAlbumMeta
    
    on getAlbumMeta(keyAttr)
        try
            repeat with currItem in albumData
                if keyAttr equals (attr of currItem) as string then
                    if (takeNew of currItem) as integer = 1 then
                        return newVal of currItem
                    else
                        return oldVal of currItem
                    end if
                end if
            end repeat
        on error
            return ""
        end try
        return ""
    end setAlbumMeta

    on newerAlbumMeta(keyAttr)
        try
            repeat with currItem in albumData
                if keyAttr equals (attr of currItem) as string then
                    if (takeNew of currItem) as integer = 1 then
                        return true
                    else
                        return false
                    end if
                end if
            end repeat
        on error
            return false
        end try
        return false
    end setAlbumMeta

    on isiTunesPlaying()
        tell application "iTunes"
            if player state is stopped then
                return false
            else
                return true
            end if
        end tell
    end isiTunesPlaying

    -- application scripts --------------------------------------------------------------------------------------------

    on cleanGUI()
        -- close both panels
        coverPanel's performClose_(me)
        metaPanel's performClose_(me)
        -- clear form
        missingLabel's setStringValue_("Tracks not yet checked. ")
        albumLabel's setStringValue_("No tracks selected in iTunes")
        artistLabel's setStringValue_("")
        yearLabel's setStringValue_("")
        genreLabel's setStringValue_("")
        imgLabel's setStringValue_("")
        sortLabel's setStringValue_("No sorting tags available.")
        commentLabel's setStringValue_("No comments available.")
        imgView's setImage_(notfoundImg)
        digitsField's setStringValue_("")
        set enabled of removeButton to false
        set enabled of deleteButton to false
        set enabled of remPrefixButton to false
        
        warn(metaBox, 0)
        warn(imgBox, 0)
        warn(sortBox, 0)
        warn(discBox, 0)
        warn(commentBox, 0)
        warn(missingBox, 0)
        warn(duplicateBox, 0)
        warn(numBox, 0)
    end cleanGUI

    on getSelection()
        topLabel's setStringValue_("Select album or tracks in iTunes first.")
        my warn(iTunesBox, 1)
        -- get selection from iTunes
        set selTracks to {}
        set noOfselTracks to 0
        try
--            with timeout of 5 seconds
                if logFlow then log "Get iTunes selection"
                tell application "iTunes"
                    if selection is not {} then -- there are tracks selected
                        set selTracks to selection
                        set noOfselTracks to count of selTracks
                        topLabel's setStringValue_((noOfselTracks as string) & " tracks selected in iTunes.")
                        my warn(iTunesBox, 0)
                    else
                        my warn(iTunesBox, 1)
                        if logErrors then tell me to log "Nothing selected!"
                    end if
                end tell
                if logFlow then log "Get iTunes selection done: " & noOfselTracks & " tracks."
--            end timeout
        on error
            my warn(iTunesBox, 2)
            topLabel's setStringValue_("Getting iTunes selection failed.")
            if logErrors then log "Getting iTunes selection failed."
        end try
        if (noOfselTracks = 0 and false) then -- turned off for testing
            try
                tell application "iTunes"
--                    with timeout of 8 seconds
                        if not current playlist = library playlist 1 then -- playlist 1 is full library
                            set selTracks to tracks of current playlist
                            set noOfselTracks to count of selTracks
                            topLabel's setStringValue_("Playlist <" & (name of current playlist) & "> with " & (noOfselTracks as string) & " tracks selected.")
                            if noOfselTracks > 200 then
                                my warn(iTunesBox, 1)
                            end if
                        else
                            my warn(iTunesBox, 2)
                            if logErrors then tell me to log "No playlist selected!"
                        end if
--                    end timeout
                end tell
            on error
                if logErrors then log "Getting playlist failed!"
                topLabel's setStringValue_("Getting iTunes playlist failed.")
                my warn(iTunesBox, 2)
            end try
        end if
    end getSelection

    on syncWithiTunes()
        if not doAutoSync then return -- case: panels are open
        set s1 to iTListener's artistToSync as string
        if s1 = "" then set s1 to iTListener's albumArtistToSync as string
        set s2 to iTListener's albumToSync as string
        if (s1 = art and s2 = alb) then
            return -- already in sync
        end if        
        if logFlow then log "Sync with iTunes"
        cleanGUI()
        set selTracks to {}
        set noOfselTracks to 0
        try
            tell application "iTunes"
--                with timeout of 4 seconds
                    set searchTerm to s1 & " " & s2
                    set selTracks to search library playlist 1 for searchTerm as string
                    if selTracks is not {} then -- there are tracks found
                        set noOfselTracks to count of selTracks
                        topLabel's setStringValue_((noOfselTracks as string) & " tracks selected of playing album in iTunes.")
                        my warn(iTunesBox, 0)
                    else
                        my warn(iTunesBox, 1)
                        topLabel's setStringValue_("No tracks selected in iTunes.")
                        if logErrors then tell me to log "Nothing synced!"
                    end if
--                end timeout
            end tell
        on error
            warn(iTunesBox, 2)
            topLabel's setStringValue_("Syncing iTunes selection failed.")
            if logErrors then log "Syncing iTunes selection failed."
        end try
        if logFlow then log "Sync with iTunes done: " & noOfselTracks & " tracks selected."
        checkTracks()
    end syncWithiTunes

    on analyseTracks()
        cleanGUI()
        getSelection()
        checkTracks()
    end analyseTracks

    on checkTracks()
        cleanGUI()
        checkDeadTracks()
        checkMetaData()
    end checkTracks

    on doCheck_(sender)
        cleanGUI()
        getSelection()
        checkTracks()
    end doCheck_

    on removeSortTags_(sender)
        try
            tell application "iTunes"
--                with timeout of 5 seconds
                    set oldfi to fixed indexing
                    set fixed indexing to true
                    repeat with aTrack in selTracks
                        set sort album artist of aTrack to ""
                        set sort artist of aTrack to ""
                        set sort album of aTrack to ""
                    end repeat
                    set fixed indexing to oldfi
--                end timeout
            end tell
            checkTracks()
        on error
            if logErrors then log "Remove sort tags failed"
        end try
    end removeSortTags_

    on clearComments_(sender)
        try
            tell application "iTunes"
--                with timeout of 5 seconds
                    set oldfi to fixed indexing
                    set fixed indexing to true
                    repeat with aTrack in selTracks
                        set comment of aTrack to ""
                    end repeat
                    set fixed indexing to oldfi
--                end timeout
            end tell
            checkTracks()
        on error
            if logErrors then log "Clear comments failed"
        end try
    end clearComments_


    on setDisc_(sender)
        set dn to 0
        set dc to 0
        try
            set dn to discNumField's intValue()
        on error
            set dn to 0
        end try
        try
            set dc to discCntField's intValue()
        on error
            set dc to 0
        end try
        if not dn = 0 then
            set num to dn as string
        else
            set num to ""
        end if
        if not dc = 0 then
            set cnt to dc as string
        else
            set cnt to ""
        end if
        try 
            tell application "iTunes"
--                with timeout of 5 seconds
                    set oldfi to fixed indexing
                    set fixed indexing to true
                    repeat with aTrack in selTracks
                        set disc number of aTrack to num
                        set disc count of aTrack to cnt
                    end repeat
                    set fixed indexing to oldfi
--                end timeout
            end tell
            checkTracks()
        on error
            if logErrors then log "Set disc number and disc count failed"
        end try
    end setDisc_

    on checkDeadTracks()
        if logFlow then log "Check duplicate/dead track files"
        set deadTracks to {}
        set enabled of removeButton to false
        set enabled of deleteButton to false
        set locList to {}
        try
            tell application "iTunes"
--                with timeout of 5 seconds
                    repeat with aTrack in selTracks
                        set trloc to aTrack's location
                        if trloc is missing value then
                            --copy aTrack to the end of deadTracks
                            set end of deadTracks to aTrack
                        else
                            set s1 to get text from 1 to -5 of (trloc as string)
                            set end of locList to s1
                        end if
                    end repeat
--                end timeout
            end tell
        on error
            if logErrors then log "Checking for dead tracks failed!"
        end try
        set noOfdeadTracks to count of deadTracks
        missingLabel's setStringValue_((noOfdeadTracks as string) & " missing track files. ")
        if noOfdeadTracks > 0 then
            if noOfdeadTracks > 2 then
                warn(missingBox, 2)
            else
                warn(missingBox, 1)
            end if
            set enabled of removeButton to true
        end if
        -- check for duplicates in
        set duplTracks to {}
        try
--            with timeout of 5 seconds
                repeat with aTrack in selTracks
                    tell application "iTunes"
                        set s1 to aTrack's location
                    end tell
                    set trloc to get text from 1 to -7 of (s1 as string) -- rem .mp3 and _X
                    if locList contains trloc as string then
                        set end of duplTracks to aTrack
                    end if
                end repeat
--            end timeout
        on error
            if logErrors then log "Checking duplicates failed!"
        end try
        set numOfDupl to count of duplTracks
        duplicateLabel's setStringValue_((numOfDupl as string) & " duplicate track files. ")
        if numOfDupl > 0 then
            if numOfDupl < noOfselTracks / 3 then
                warn(duplicateBox, 1)
            else
                warn(duplicateBox, 2)
            end if
            set enabled of deleteButton to true
        end if
        if logFlow then log "Check duplicate/dead track files done."
    end checkDeadTracks

    on removeDeadTracks_(sender)
        try
            tell application "iTunes"
--                with timeout of 5 seconds
                    set oldfi to fixed indexing
                    set fixed indexing to true
                    repeat with i from 1 to noOfdeadTracks
                        set aTrack to item i of deadTracks
                        set dbid to aTrack's database ID
                        --delete aTrack
                        delete (some track of library playlist 1 whose database ID is dbid)
                    end repeat
--                end timeout
                set fixed indexing to oldfi
            end tell
            analyseTracks()
        on error
            if logErrors then log "Remove dead tracks failed!"
        end try
    end removeDeadTracks_

    on deleteDuplicates_(sender)
        try
            repeat with aTrack in duplTracks
--                with timeout of 3 seconds
                    tell application "iTunes"
                        set trloc to location of aTrack
                        set dbid to aTrack's database ID
                        delete (some track of library playlist 1 whose database ID is dbid)
                    end tell
--                end timeout
                tell application "Finder" to delete trloc
            end repeat
        on error
            if logErrors then log "Delete duplicates failed!"
        end try
        analyseTracks()
    end deleteDuplicates_

    on checkMetaData() -- check track numbers, same album, same artist
        if logFlow then log "checkMetaData of " & noOfselTracks & " tracks"
        if noOfselTracks = 0 then
            set enabled of metaButton to false
            set enabled of coverButton to false
            set enabled of discButton to false
            set enabled of sortButton to false
            set enabled of commentButton to false
            set enabled of convertNumButton to false
            numLabel's setStringValue_("Missing track numbers n/a.")
            sortLabel's setStringValue_("No sorting tags available.")
            commentLabel's setStringValue_("No comments available.")
            discLabel's setStringValue_("No disc groups available.")
            return
        end if
        set coverImg to missing value
        try
            tell application "iTunes"
--                with timeout of 15 seconds
                    set firstTrack to item 1 of selTracks
                    set art to artist of firstTrack
                    set albart to album artist of firstTrack
                    set alb to album of firstTrack
                    set sameArtist to true
                    set sameAlbum to true
                    set r to year of firstTrack
                    if (r = 0) then
                        set releaseYear to ""
                    else
                        set releaseYear to r as string
                    end if
                    set albGenre to genre of firstTrack
                    set totalTracks to track count of firstTrack
                    set discNo to disc number of firstTrack
                    set discCount to disc count of firstTrack
                    set sameDiscNo to true
                    set sameDiscCount to true
                    set isCompilation to compilation of firstTrack
                    set sortAlb to sort album of firstTrack
                    set sortAlbArt to sort album artist of firstTrack
                    set sortArt to sort artist of firstTrack
                    set tempComment to comment of firstTrack
                    set sameComment to true
                    if length of (sortAlb as string & sortAlbArt as string & sortArt as string) > 0 then
                        set sortTags to true
                    else
                        set sortTags to false
                    end if
                    set numTracks to {}
                    set enabled of convertNumButton to false
                    set idx to 0
                    repeat with aTrack in selTracks
                        set idx to idx + 1
                        if (idx >1) then -- first already used for initializing sameX
                            if sameAlbum then
                                if alb is not equal to album of aTrack
                                    set sameAlbum to false
                                end if
                            end if
                            if sameArtist then
                                if art is not equal to artist of aTrack
                                    set sameArtist to false
                                end if
                            end if
                            if sameDiscNo then
                                if discNo is not equal to disc number of aTrack
                                    set sameDiscNo to false
                                end if
                            end if
                            if sameDiscCount then
                                if discCount is not equal to disc count of aTrack
                                    set sameDiscCount to false
                                end if
                            end if
                            if sameComment then
                                if tempComment is not equal to comment of aTrack
                                    if tempComment = "" then
                                        set tempComment to comment of aTrack
                                    end if
                                    set sameComment to false
                                end if
                            end if
                        end if
                        set nr to aTrack's track number
                        if nr is 0 then
                            if kind of aTrack contains "audio" then --only check numbering of audio files
                                --copy aTrack to the end of numTracks
                                set end of numTracks to aTrack
                            end if
                        end if
                    end repeat
                    if logFlow then log "Tracks collected."
                    if sameAlbum then
                        if logFlow then tell me to log "Get cover"
                        if (artworks of firstTrack exists) then
                            try 
                              -------------------------------------------------------------------------------------------------
                              if (true) then
                                  if logFlow then tell me to log "write cover to temp dir"
--                                  with timeout of 2 seconds
                                    set coverData to get raw data of artwork 1 of firstTrack
                                    -- image needs to be saved to a file and then read, no direct conversion available
                                    set fileRef to (open for access file (tempDir & "coverart") with write permission)
                                    set eof fileRef to 0
                                    write coverData to fileRef
                                    close access fileRef
                                    set coverExists to true
--                                  end timeout
                                  if logFlow then tell me to log "write cover to temp dir done."
                              else
                                  tell me to log "Format: " & (format of artwork 1 of firstTrack) as text
                                  --set coverData to get raw data of artwork 1 of firstTrack
                                  --set my coverImg to current application's NSHelpers's imageFromData_(get raw data of artwork 1 of firstTrack)
                                  set my coverImg to current application's NSHelpers's imageFromArtwork_(firstTrack)
                                  tell me to log "imageFromArtwork done."
                                  --set aw to get artwork 1 of firstTrack
                                  --set my coverImg to current application's NSImage's alloc's initWithData_(aw's rawData)
                                  if not my coverImg exists then tell me to log "PROBLEM initializing image."
                                  set coverExists to true
                                end if
                                
                            on error
                                if logErrors then tell me to log "Get cover failed."
                                set coverExists to false
                            end try
                        else
                            set coverExists to false
                        end if
                        if logFlow then tell me to log "Get cover done."
                    end if
--                end timeout
            end tell
        on error
            if logErrors then log "Checking meta data failed!"
        end try
        if logFlow then log "Setup GUI"
        imgLabel's setStringValue_("")
        discCntField's setStringValue_("")
        discNumField's setStringValue_("")
        if sameAlbum then
            albumLabel's setStringValue_(alb)
            if (albart = "" or releaseYear = "" or albGenre = "") then
                warn(metaBox, 1)
            end if
            if isCompilation then
                artistLabel's setStringValue_(albart & " (Compilation)")
            else
                artistLabel's setStringValue_(albart)
            end if
            yearLabel's setStringValue_(releaseYear)
            genreLabel's setStringValue_(albGenre)
            if sortTags then
                set s to ""
                if (sortAlbArt = sortArt) then
                    set s to sortAlbArt
                else
                    set s to sortAlbArt & "; " & sortArt
                end if
                if not s = "" then
                    set s to s & "; " & sortAlb
                else
                    set s to sortAlb
                end if
                sortLabel's setStringValue_("Sort Tags: " & s)
            else
                sortLabel's setStringValue_("No sorting tags.")
            end if
            if sameDiscNo then
                discLabel's setStringValue_("Disc Grouping:")
                if discNo = 0 then
                    set dn to ""
                else
                    set dn to discNo as string
                end if
                discNumField's setStringValue_(dn)
            else
                discLabel's setStringValue_("Mixed disc grouping!")
                warn(discBox, 1)
            end if
            if sameDiscCount then
                if discCount = 0 then
                    set dc to ""
                else
                    set dc to discCount as string
                end if
                discCntField's setStringValue_(dc)
            else
                warn(discBox, 2)
            end if
            if coverExists then
                try
                  -----------------------------------------------------------------------------
                  if (true)
                    if logFlow then tell me to log "read cover from temp dir"
--                    with timeout of 2 seconds
                        set coverImg to current application's NSImage's alloc's initWithContentsOfFile_(POSIX path of (tempDir & "coverart"))
--                    end timeout
                    if logFlow then tell me to log "read cover from temp dir done."
                  else
                    log "now resize existing cover"
                  end if
                    set imgW to coverImg's getWidth as integer
                    set imgH to coverImg's getHeight as integer
                    imgLabel's setStringValue_((imgW as text) & "x" & (imgH as text) & " pixels")
                    coverImg's setSize_({128, 128})
                    imgView's setImage_(coverImg)
                    if imgW < 500 then
                        warn(imgBox, 1)
                    end if
                on error
                    if logErrors then log "Reading cover failed!"
                end try
            else
                imgView's setImage_(notfoundImg)
                imgLabel's setStringValue_("No Cover!")
                warn(imgBox, 2)
            end if
        else
            albumLabel's setStringValue_("Tracks from several albums selected.")
            artistLabel's setStringValue_("")
            yearLabel's setStringValue_("")
            genreLabel's setStringValue_("")
            imgLabel's setStringValue_("")
            sortLabel's setStringValue_("No sorting tags available.")
            discLabel's setStringValue_("No disc groups available.")
            imgView's setImage_(multiImg)
        end if
        set enabled of metaButton to sameAlbum
        set enabled of coverButton to sameAlbum
        set enabled of discButton to sameAlbum
        set noOfnumTracks to count of numTracks
        numLabel's setStringValue_((noOfnumTracks as string) & " missing track numbers. ")
        -- eval prefix digits
        set prefixDigits to 0
        if noOfnumTracks > 0 then
            warn(numBox, 1)
            set enabled of convertNumButton to true
            set tr to item 1 of numTracks
        else
            set enabled of convertNumButton to false
            set tr to item 1 of selTracks
        end if
        set trname to name of tr
        set cnt to 1
        set cond to true
        repeat while cond = true and cnt <= length of trname
            set c to (character cnt of trname)
            if ((c >= "A")) then
                set cond to false
            else
                set cnt to cnt + 1
            end if
        end repeat
        set prefixDigits to cnt - 1
        if prefixDigits > 0
            digitsField's setStringValue_(prefixDigits as string)
            set enabled of remPrefixButton to true
        else
            digitsField's setStringValue_("")
            set enabled of remPrefixButton to false
        end if
        if tempComment = "" then
            commentLabel's setStringValue_("No comments in selected tracks.")
            set enabled of commentButton to false
        else
            if sameComment then
                commentLabel's setStringValue_("Comment: "& tempComment as String)
                warn(commentBox, 1)
            else
                commentLabel's setStringValue_("Diverse comments in selected tracks.")
            end if
            set enabled of commentButton to true
        end if
        if logFlow then log "checkMetaData done."
    end checkMetaData

    on convertNumbers()
        tell application "iTunes"
--            with timeout of 5 seconds
                set oldfi to fixed indexing
                set fixed indexing to true
                repeat with i from 1 to noOfnumTracks
                    set aTrack to item i of numTracks
                    --convert track number from track name prefix
                    if class of aTrack is file track then
                        try
                            set n to my getIntFromString(get aTrack's name as string)
                            if (n is not 0) and (n < 1000) then
                                set aTrack's track number to n
                            end if
                        on error
                            tell me to if logErrors then log "Convert numbers failed!"
                        end try
                    end if
                end repeat
                set fixed indexing to oldfi
--            end timeout
        end tell
        checkTracks()
    end convertNumbers
    
    on doConvert_(sender)
        convertNumbers()
        checkTracks()
    end doConvert_

    on setDigits_(sender)
        try
            set prefixDigits to digitsField's intValue()
        on error
            set prefixDigits to 0
        end try
        if prefixDigits > 0
            set enabled of remPrefixButton to true
        else
            set enabled of remPrefixButton to false
        end if
    end setDigits_

    on removePrefix()
        try
            tell application "iTunes"
--                with timeout of 5 seconds
                    set oldfi to fixed indexing
                    set fixed indexing to true
                    if (noOfnumTracks > 0) then
                        repeat with i from 1 to noOfnumTracks
                            try
                                set aTrack to item i of numTracks
                                --remove prefix from track name
                                set trname to name of aTrack
                                set str1 to ((characters (prefixDigits + 1) thru -1 of trname) as string) --trim first prefixDigits
                                set name of aTrack to str1
                            end try
                        end repeat
                    else
                        repeat with i from 1 to noOfselTracks
                            set aTrack to item i of selTracks
                            --remove prefix from track name 
                            set trname to name of aTrack
                            set str1 to ((characters (prefixDigits + 1) thru -1 of trname) as string) --trim first prefixDigits
                            set name of aTrack to str1
                        end repeat
                    end if
                    set fixed indexing to oldfi
--                end timeout
            end tell
        on error
            if logErrors then log "Remove prefix failed!"
        end try
    end removePrefix

    on doRemPrefix_(sender)
        removePrefix()
        checkTracks()
    end doRemPrefix_

    -- album cover ------------------------------------------------------------------------------------------------------
    on closeCoverSearch_(sender)
        coverPanel's performClose_(me)
        set doAutoSync to true
    end doCoverSearch_

    on doCoverSearch_(sender)
        set doAutoSync to false
        cpAlbumLabel's setStringValue_(alb)
        if not albart = "" then
            cpArtistLabel's setStringValue_(albart)
        else
            cpArtistLabel's setStringValue_(art)
        end if
        searchCover_(sender)
        metaPanel's performClose_(me)
        coverPanel's orderFront_(me)
    end doCoverSearch_

    on searchCover_(sender)
        set searchAlb to cpAlbumLabel's stringValue()
        set searchArt to cpArtistLabel's stringValue()
        set searchSource to cpSourcePopup's indexOfSelectedItem
        if (searchSource as integer = 0) then set idx to searchiTunesAlbum(searchAlb, searchArt)
        if (searchSource as integer = 1) then set idx to searchDiscogsAlbum(searchAlb, searchArt)
        if (searchSource as integer = 2) then set idx to searchGoogleCover(searchAlb, searchArt)
        if idx > 0 then
            cpAlbumsPopup's selectItemAtIndex_(idx -1) -- popup starts at index 0
            grabCover_(me)
        end if
    end searchCover_

    on grabCover_(sender)
        set cpImg to missing value
        set searchIdx to cpAlbumsPopup's indexOfSelectedItem() + 1
        set searchSource to cpSourcePopup's indexOfSelectedItem
        if (searchSource as integer = 0) then set coverURL to grabiTunesCoverURL(searchIdx)
        if (searchSource as integer = 1) then set coverURL to grabDiscogsCoverURL(searchIdx)
        if (searchSource as integer = 2) then set coverURL to grabGoogleCoverURL(searchIdx)

        if coverURL is not equal to ""
            set theURL to current application's NSURL's URLWithString_(coverURL)
            try
                set cpImg to current application's NSImage's alloc's initWithContentsOfURL_(theURL)
            on error
                if logErrors then log "Cover image not found at " & coverURL
            end try
        else
            if logErrors then log "No URL for cover found"
        end if
        if cpImg is equal to missing value then
            coverView's setImage_(notfoundImg)
            cpImgLabel's setStringValue_("no image found")
            set enabled of cpSetButton to false
        else
            set imgW to cpImg's getWidth as integer
            set imgH to cpImg's getHeight as integer
            cpImg's setSize_({imgW, imgH})
            coverView's setImage_(cpImg)
            cpImgLabel's setStringValue_((imgW as text) & "x" & (imgH as text))
            set enabled of cpSetButton to true
        end if
    end grabCover_

    on grabiTunesCoverURL(searchIdx)
        try
            set res1 to coverURL of item searchIdx of albumsList
            if res1 is not equal to missing value then
                set res2 to replace_chars(res1 as string, "100x100", "1200x1200") -- 600x600, 1200x1200, 1400x1400 available?
                return res2
            else
                if logErrors then log "iTunes cover not found"
                return ""
            end if
        on error
            if logErrors then log "Getting iTunes cover failed"
            return ""
        end try
    end grabiTunesCoverURL

    on grabDiscogsCoverURL(searchIdx)
        set releaseNr to albumID of item searchIdx of albumsList
        try
            set thisURL to "http://api.discogs.com/releases/" & releaseNr as string
            if logJSON then log thisURL
            set dict2 to current application's NSHelpers's convertJSONfromURL_(thisURL)
            if logJSON then log dict2
            set res1 to missing value
            repeat with a in images of dict2
                if res1 = missing value then
                    set res1 to uri of a as string
                end if
                if |type| of a as string = "primary" then
                    set res1 to uri of a as string
                    exit repeat
                end if
            end repeat
        end try
        if res1 is not equal to missing value then
            return res1
        end if
        if logErrors then log "Discogs cover not found"
        return ""
    end grabDiscogsCoverURL

    on searchGoogleCover(sAlb, sArt)
        set albList to {}
        try
            if not (sArt equal "") then
                set s1 to sArt as string & "+" & sAlb as string
                else
                set s1 to sAlb as string
            end if
            set term to replace_chars(s1, " ", "+")
            -- note: thsi Web APIis deprcated! The new Custom Serarch API needs a key and will be limited!!
            set thisURL to "https://ajax.googleapis.com/ajax/services/search/images?v=1.0&q=" & term & "+Cover+Front&as_filetype=jpg&imgsz=xlarge"
            if logJSON then log thisURL
            set dict to current application's NSHelpers's convertJSONfromURL_(thisURL)
            if logJSON then log dict
            -- create albumsList with search results
            set idx to 1
            set limit to count of results of responseData of dict as integer
            log limit
            if limit > 15 then set limit to 15
            repeat while idx <= limit -- remark: "misuse of AlbumInfo!
                set albInfo to current application's AlbumInfo's alloc()'s init()
                set res1 to titleNoFormatting of item idx of results of responseData of dict as text
                set albumTitle of albInfo to res1
                set imgW to |width| of item idx of results of responseData of dict as integer
                set imgH to |height| of item idx of results of responseData of dict as integer
                set country of albInfo to "| " & imgW as string & "x" & imgH as string
                set res1 to |visibleUrl| of item idx of results of responseData of dict as text
                set albumType of albInfo to res1 as string
                set res1 to |url| of item idx of results of responseData of dict as text
                set coverURL of albInfo to res1 as string
                albInfo's createSummary()
                set end of albList to albInfo
                set idx to idx + 1
            end repeat
        on error
            if logErrors then log "Searching Google images failed"
        end try
        tell albumsListController
            removeObjects_(arrangedObjects())
            addObjects_(albList)
        end tell
        -- idea: find best fit
        return 1
    end searchGoogleCover

    on grabGoogleCoverURL(searchIdx)
        try
            set res1 to coverURL of item searchIdx of albumsList
            if res1 is not equal to missing value then
                return res1
            else
                if logErrors then log "Google cover not found"
                return ""
            end if
        on error
            if logErrors then log "Getting Google cover failed"
            return ""
        end try
    end grabGoogleCoverURL

    on setCover_(sender)
        if logFlow then log "setCover"
        -- image needs to be saved to a file and then read, no direct conversion available
        set newFile to (tempdir & "newcoverart") -- is HFS style
        -- write image in cover panel to temp file -- needs POSIX style
        set res to cpImg's saveToFile_(POSIX path of (path to temporary items from user domain) & "newcoverart")
            try
--              with timeout of 8 seconds
                if logFlow then log "Set new covers for " & noOfselTracks & " tracks"
                tell application "iTunes"
                    repeat with i from 1 to noOfselTracks
                        set aTrack to item i of selTracks
                        --if (artworks of aTrack exists) then
                            --set cnt to count of artworks of aTrack
                            --if logFlow then tell me to log ">" & cnt
                            --if cnt > 0 then
                            --    delete artwork 1 of aTrack
                            --    if logFlow then tell me to log "artwork deleted."
                            --end if
                        --end if
                        --set album cover
                        try
                            -- WARNING: problems when setting cover --> iTunes will block!!!!
                            set data of artwork 1 of aTrack to (read file newFile as picture)
                            --set data of artwork 1 of aTrack to (read fRef from 1 as picture)
                            if logFlow then tell me to log track number of aTrack as string & " done."
                        on error
                            if logErrors then tell me to log "setting artwork failed."
                        end try
                    end repeat
                    --refresh aTrack
                end tell
                if logFlow then log "Set new covers done."
--              end timeout
            on error
                if logErrors then log "Setting new Cover Art failed: " & newFile as string
            end try
        coverPanel's performClose_(me)
        set doAutoSync to true
        if logFlow then log "setCover done."
        checkTracks()
    end setCover_

    -- album meta info ------------------------------------------------------------------------------------------------
    on closeMetaSearch_(sender)
        metaPanel's performClose_(me)
        set doAutoSync to true
    end doMetaSearch_

    on doMetaSearch_(sender)
        set doAutoSync to false
        mpAlbumLabel's setStringValue_(alb)
        if not albart = "" then 
            mpArtistLabel's setStringValue_(albart)
        else
            mpArtistLabel's setStringValue_(art)
        end if
        createMetaData()
        searchMeta_(sender)
        coverPanel's performClose_(me)
        metaPanel's orderFront_(me)
    end doMetaSearch_

    on createMetaData() -- get meta data from local iTunes
        set mpIncludeState to 0
        -- create album info data structure
        set metaList to {}
        set end of metaList to {attr:"Album", oldVal:alb, newVal:"", takeNew:0}
        set end of metaList to {attr:"Artist", oldVal:albart, newVal:"", takeNew:0}
        set end of metaList to {attr:"Year", oldVal:releaseYear, newVal:"", takeNew:0}
        set end of metaList to {attr:"Genre", oldVal:albGenre, newVal:"", takeNew:0}
        set end of metaList to {attr:"Tracks", oldVal:totalTracks, newVal:"", takeNew:0}
        tell albumController
            removeObjects_(arrangedObjects())
            addObjects_(metaList)
        end tell
        --create tracks info
        set tracksList to {}
        try
            tell application "iTunes"
                set oldfi to fixed indexing
                set fixed indexing to true
                repeat with i from 1 to noOfselTracks
--                    with timeout of 3 seconds
                        set aTrack to item i of selTracks
                        --create track entry
                        set trNo to track number of aTrack
                        set trTitle to name of aTrack as string
                        set trArtist to artist of aTrack as string
                        set trComposer to composer of aTrack as string
                        set trComment to comment of aTrack as string
                        set trDiscNo to disc number of aTrack as string
                        set trDiscCount to disc count of aTrack as string
                        set end of tracksList to {trackNo:trNo, trackName:trTitle, trackArtist:trArtist, trackComposer:trComposer, trackComment:trComment, trackDiscNo:trDiscNo, trackDiscCount:trDiscCount}
--                    end timeout
                end repeat
                set fixed indexing to oldfi
            end tell
        on error
            if logErrors then log "Create meta data failed"
        end try
        tell tracksController
            removeObjects_(arrangedObjects())
            addObjects_(tracksList)
        end tell
    end

    on searchMeta_(sender)
        set searchAlb to mpAlbumLabel's stringValue()
        set searchArt to mpArtistLabel's stringValue()
        set searchSource to mpSourcePopup's indexOfSelectedItem
        if (searchSource as integer = 0) then set idx to searchiTunesAlbum(searchAlb, searchArt)
        if (searchSource as integer = 1) then set idx to searchDiscogsAlbum(searchAlb, searchArt)
        if (searchSource as integer = 2) then set idx to searchBrainzAlbum(searchAlb, searchArt)
        if idx > 0 then
            mpAlbumsPopup's selectItemAtIndex_(idx -1) -- popup starts at index 0
            grabMeta_(me)
        end if
    end searchMeta_

    on grabMeta_(sender)
        set searchIdx to mpAlbumsPopup's indexOfSelectedItem() + 1
        set searchSource to mpSourcePopup's indexOfSelectedItem
        if (searchSource as integer = 0) then grabiTunesMeta(searchIdx)
        if (searchSource as integer = 1) then grabDiscogsMeta(searchIdx)
        if (searchSource as integer = 2) then grabBrainzMeta(searchIdx)
    end grabMeta_

    on searchiTunesAlbum(sAlb, sArt) -- search iTunes Store
        set albList to {}
        try
            if not (sArt equal "") then
                set s1 to sArt as string & "+" & sAlb as string
            else
                set s1 to sAlb as string
            end if
            set term to replace_chars(s1, " ", "+")
            set thisURL to "https://itunes.apple.com/search?term=" & term & "&media=music&entity=album"
            if logJSON then log thisURL
            set dict to current application's NSHelpers's convertJSONfromURL_(thisURL)
            if logJSON then log dict
            -- create albumsList with search results
            set idx to 1
            set limit to resultCount of dict as integer
            if limit > 15 then set limit to 15
            repeat while idx <= limit
                set albInfo to current application's AlbumInfo's alloc()'s init()
                set res1 to artistName of item idx of results of dict as text
                set albumArtist of albInfo to res1
                set res1 to collectionName of item idx of results of dict as text
                set albumTitle of albInfo to res1
                set res1 to releaseDate of item idx of results of dict as text
                set releaseYear of albInfo to (getIntFromString(res1) as string)
                set res1 to country of item idx of results of dict as text
                set country of albInfo to res1
                set res1 to primaryGenreName of item idx of results of dict as text
                set albumGenre of albInfo to res1
                set res1 to artworkUrl100 of item idx of results of dict as text
                set coverURL of albInfo to res1
                set res1 to trackCount of item idx of results of dict as integer
                set trackCount of albInfo to res1
                try
                    set res1 to discCount of item idx of results of dict as integer -- not always defined!!!
                    set discCount of albInfo to res1
                end try
                set res1 to collectionId of item idx of results of dict as text
                set albumID of albInfo to res1
                albInfo's createSummary()
                set end of albList to albInfo
                set idx to idx + 1
            end repeat
        on error
            if logErrors then log "Searching iTunes store failed"
        end try
        tell albumsListController
            removeObjects_(arrangedObjects())
            addObjects_(albList)
        end tell        
        -- idea: find best fit
        return 1
    end searchiTunesAlbum
        
    on grabiTunesMeta(searchIdx) -- grab info from iTunes Store
        set newtracksList to {}
        try
            -- create new album meta
            -- trackCount, releaseDate, artistName, collectionName, primaryGenreName
            set res1 to albumArtist of item searchIdx of albumsList
            setAlbumMeta("Artist", res1)
            set res1 to albumTitle of item searchIdx of albumsList
            setAlbumMeta("Album", res1)
            set res1 to releaseYear of item searchIdx of albumsList
            setAlbumMeta("Year", res1 as string)
            set res1 to albumGenre of item searchIdx of albumsList
            setAlbumMeta("Genre", res1)
            set res1 to trackCount of item searchIdx of albumsList
            setAlbumMeta("Tracks", res1)
            set term to albumID of item searchIdx of albumsList
            set thisURL to "https://itunes.apple.com/lookup?id=" & term & "&entity=song"
            if logJSON then log thisURL
            set dict2 to current application's NSHelpers's convertJSONfromURL_(thisURL)
            if logJSON then log results of dict2
            -- create new tracks data
            set idx to 0
            repeat with currItem in (results of dict2)
                if idx > 0 then -- first entry is album not track info
                    set trInfo to current application's TrackInfo's alloc()'s init()
                    set r to trackNumber of currItem
                    set trackNo of trInfo to r as integer
                    set trackName of trInfo to trackName of currItem
                    set trackArtist of trInfo to artistName of currItem
                    -- composer not available, copy from current
                    if idx <= count of tracksData then
                        set trackComposer of trInfo to trackComposer of item idx of tracksData
                    end if
                    set end of newtracksList to trInfo
                end if
                set idx to idx + 1
            end repeat
            if idx > 0 then set mpIncludeState to 1
        on error
            if logErrors then log "Getting iTunes album info failed"
        end try
        tell newtracksController
            removeObjects_(arrangedObjects())
            addObjects_(newtracksList)
        end tell
    end grabiTunesMeta

    on searchBrainzAlbum(sAlb, sArt)
        set albList to {}
        try
            if not (sArt equal "") then
                set s1 to "artist:" & sArt as string & "+album:" & sAlb as string
                else
                set s1 to sAlb as string
            end if
            set term to replace_chars(s1, " ", "+")
            set thisURL to "http://www.musicbrainz.org/ws/2/release/?query=" & term & "&limit=15&fmt=json"
            if logJSON then log thisURL
            set dict1 to current application's NSHelpers's convertJSONfromURL_(thisURL)
            if logJSON then log dict1
            -- create albumsList with search results
            set idx to 1
            set limit to count of releases of dict1
            repeat while idx <= limit
                set albInfo to current application's AlbumInfo's alloc()'s init()
                set res1 to |name| of artist of item 1 of |artist-credit| of item idx of releases of dict1 as text
                set albumArtist of albInfo to res1
                set res1 to title of item idx of releases of dict1 as text
                set albumTitle of albInfo to res1
                try
                    set res1 to |date| of item idx of releases of dict1 as text
                    set releaseYear of albInfo to (getIntFromString(res1) as string)
                end try
                try
                    set res1 to country of item idx of releases of dict1 as text
                    set country of albInfo to res1
                end try
                set res1 to |track-count| of item idx of releases of dict1 as integer
                set trackCount of albInfo to res1
                set res1 to |id| of item idx of releases of dict1 as text
                set albumID of albInfo to res1
                albInfo's createSummary()
                set end of albList to albInfo
                set idx to idx + 1
            end repeat
        on error
            if logErrors then log "Searching MusicBrainz server failed"
        end try
        tell albumsListController
            removeObjects_(arrangedObjects())
            addObjects_(albList)
        end tell
        -- idea: find best fit
        return 1
    end searchBrainzAlbum

    on grabBrainzMeta(searchIdx) -- grab info from MusicBrainz server
        set newtracksList to {}
        set releaseNr to albumID of item searchIdx of albumsList
        try
            set thisURL to "http://www.musicbrainz.org/ws/2/release/" & releaseNr as string & "?inc=artist-credits+recordings&fmt=json"
            if logJSON then log thisURL
            set dict2 to current application's NSHelpers's convertJSONfromURL_(thisURL)
            if logJSON then log dict2
            -- create new album meta
            set res1 to |name| of item 1 of |artist-credit| of dict2 as text
            setAlbumMeta("Artist", res1)
            set res1 to title of dict2 as text
            setAlbumMeta("Album", res1)
            set res1 to |date| of dict2 as text
            setAlbumMeta("Year", getIntFromString(res1) as string)
            --setAlbumMeta("Genre", res1)
            set res1 to |track-count| of item 1 of media of dict2 as text
            setAlbumMeta("Tracks", res1)
            log res1 as string & " track count"
            -- create new tracks data
            set idx to 0
            repeat with currItem in (|tracks| of item 1 of media of dict2)
                set trInfo to current application's TrackInfo's alloc()'s init()
                set trackNo of trInfo to |number| of currItem
                set trackName of trInfo to |title| of currItem
                set trackArtist of trInfo to |name| of artist of item 1 of |artist-credit| of currItem
                -- hmmm, composer is missing
                set end of newtracksList to trInfo
                set idx to idx + 1
            end repeat
            if idx > 0 then set mpIncludeState to 1
        on error
            if logErrors then log "Getting MusicBrainz album info failed"
        end try
        tell newtracksController
            removeObjects_(arrangedObjects())
            addObjects_(newtracksList)
        end tell
    end grabBrainzMeta

    on searchDiscogsAlbum(sAlb, sArt)
        set albList to {}
        try
            if not (sArt equal "") then
                set s1 to sArt as string & "+" & sAlb as string
                else
                set s1 to sAlb as string
            end if
            set term to replace_chars(s1, " ", "+")
            set thisURL to "http://api.discogs.com/search?q=" & term & "&type=release&f=json"
            if logJSON then log thisURL
            set dict to current application's NSHelpers's convertJSONfromURL_(thisURL)
            set numRes to 0
            if not dict = missing value then
                if logJSON then log dict
                set numRes to (numResults of searchresults of search of resp of dict) as integer
            end if
            -- create albumsList with search results
            set idx to 1
            if numRes > 15 then
                set limit to 15
            else
                set limit to numRes
            end if
            repeat while idx <= limit
                set albInfo to current application's AlbumInfo's alloc()'s init()
                set res1 to title of item idx of results of searchresults of search of resp of dict as text
                set albumTitle of albInfo to res1
                set res1 to uri of item idx of results of searchresults of search of resp of dict as text
                set res2 to getIntFromStringEnd(res1 as string)
                set albumID of albInfo to res2
                albInfo's createSummary()
                set end of albList to albInfo
                set idx to idx + 1
            end repeat
        on error
            if logErrors then log "Searching Discogs server failed."
        end try
        tell albumsListController
            removeObjects_(arrangedObjects())
            addObjects_(albList)
        end tell
        -- idea: find best fit
        return 1
    end searchDiscogsAlbum

    on grabDiscogsMeta(searchIdx)
        set newtracksList to {}
        try
            set releaseNr to albumID of item searchIdx of albumsList
            set thisURL to "http://api.discogs.com/releases/" & releaseNr as string
            if logJSON then log thisURL
            set dict2 to current application's NSHelpers's convertJSONfromURL_(thisURL)
            if logJSON then log dict2
            -- create new album meta
            set thisArtist to |name| of item 1 of artists of dict2 as text
            setAlbumMeta("Artist", thisArtist)
            set res2 to title of dict2 as text
            setAlbumMeta("Album", res2)
            try
                set res2 to item 1 of genres of dict2 as text
                setAlbumMeta("Genre", res2)
            end try
            set res2 to |year| of dict2 as text
            setAlbumMeta("Year", res2)
            set res2 to count of tracklist of dict2
            setAlbumMeta("Tracks", res2)
            -- create new tracks data
            set idx to 0
            repeat with currItem in (tracklist of dict2)
                set trInfo to current application's TrackInfo's alloc()'s init()
                set res1 to |position| of currItem as text
                set trackNo of trInfo to getIntFromStringEnd(res1) as integer
                set trackName of trInfo to |title| of currItem as text
                set trackArtist of trInfo to thisArtist -- collect artists?
                -- collect composers: check role "Written-By"
                try
                    set comp to ""
                    --log (extraartists of currItem) as string
                    repeat with a in (extraartists of currItem)
                        log |name| of a as string
                        if role of a as string = "Written-By" then
                            if comp = "" then
                                set comp to |name| of a as string
                            else
                                set comp to comp & ", " & |name| of a as string
                            end if
                        end if
                    end repeat
                    set trackComposer of trInfo to comp
                end try
                set end of newtracksList to trInfo
                set idx to idx + 1
            end repeat
        if idx > 0 then set mpIncludeState to 1
        on error
            if logErrors then log "Getting Discogs album info failed."
        end try
        tell newtracksController
            removeObjects_(arrangedObjects())
            addObjects_(newtracksList)
        end tell
    end grabDiscogsMeta

    on copyCurrentTracks_(sender)
        set newtracksList to {}
        try
            tell application "iTunes"
--                with timeout of 6 seconds
                    set oldfi to fixed indexing
                    set fixed indexing to true
                    repeat with i from 1 to noOfselTracks
                        set trInfo to current application's TrackInfo's alloc()'s init()
                        set aTrack to item i of selTracks
                        set trackNo of trInfo to track number of aTrack
                        set trackName of trInfo to name of aTrack as string
                        set trackArtist of trInfo to artist of aTrack as string
                        set trackComposer of trInfo to composer of aTrack as string
                        set trackComment of trInfo to comment of aTrack as string
                        set trackDiscNo of trInfo to disc number of aTrack as string
                        set trackDiscCount of trInfo to disc count of aTrack as string
                        set end of newtracksList to trInfo
                    end repeat
                    set fixed indexing to oldfi
--                end timeout
            end tell
        on error
            if logErrors then log "Copy current track info failed"
        end try
        tell newtracksController
            removeObjects_(arrangedObjects())
            addObjects_(newtracksList)
        end tell
    end copyCurrentTracks

    on capitalizeProper_(sender)
        try
            repeat with trInfo in newtracksData
                set s to capitalizeWordsWithExceptions(trackName of trInfo as string, lowercase_words)
                set trackName of trInfo to s
                set s to capitalizeWordsWithExceptions(trackArtist of trInfo as string, lowercase_words)
                set trackArtist of trInfo to s
                set s to capitalizeWordsWithExceptions(trackComposer of trInfo as string, lowercase_words)
                set trackComposer of trInfo to s
            end repeat
        on error
            if logErrors then log "capitalizeProper failed!"
        end try
    end capitalizeProper_

    on setMetaData_(sender)
        set inclTracks to mpIncludeButton's state as integer
        if logFlow then log "Set meta data"
        try
            tell application "iTunes"
                set oldfi to fixed indexing
                set fixed indexing to true
                repeat with i from 1 to noOfselTracks
                    if logFlow then tell me to log "set meta data on track " & i
--                    with timeout of 5 seconds
                        set curTrack to item i of selTracks -- current iTunes track
                        set oldTrack to item i of tracksData -- record
                        set newTrack to item i of newtracksData -- TrackInfo
                        -- set album meta info
                        if my newerAlbumMeta("Album") then
                            set album of curTrack to my getAlbumMeta("Album") as string
                        end if
                        if my newerAlbumMeta("Artist") then
                            set album artist of curTrack to my getAlbumMeta("Artist") as string
                        end if
                        if my newerAlbumMeta("Year") then
                            set year of curTrack to my getAlbumMeta("Year") as string
                        end if
                        if my newerAlbumMeta("Genre") then
                            set genre of curTrack to my getAlbumMeta("Genre") as string
                        end if
                        if my newerAlbumMeta("Tracks") then
                            set track count of curTrack to my getAlbumMeta("Tracks") as string
                        end if
                        if inclTracks = 1 then
                            try
                                if not trackNo of oldTrack as integer = trackNo of newTrack as integer then
                                    set track number of curTrack to trackNo of newTrack as integer
                                end if
                                if not trackName of oldTrack = trackName of newTrack then
                                    set name of curTrack to trackName of newTrack as string
                                end if
                                if not trackArtist of oldTrack = trackArtist of newTrack then
                                    set artist of curTrack to trackArtist of newTrack as string
                                end if
                                if not trackComposer of oldTrack = trackComposer of newTrack then
                                    set composer of curTrack to trackComposer of newTrack as string
                                end if
                                if not trackComent of oldTrack = trackComment of newTrack then
                                    set comment of curTrack to trackComent of newTrack as string
                                end if
                                if not trackDiscNo of oldTrack = trackDiscNo of newTrack then
                                    set disc number of curTrack to trackDiscNo of newTrack as string
                                end if
                                if not trackDiscCount of oldTrack = trackDiscCount of newTrack then
                                    set disc count of curTrack to trackDiscCount of newTrack as string
                                end if
                            end try
                        end if
--                    end timeout
                    if logFlow then tell me to log "set meta data on track " & i & " done."
                end repeat
                set fixed indexing to oldfi
            end tell
        on error
            if logErrors then log "Setting meta data failed!"
        end try
        metaPanel's performClose_(me)
        set doAutoSync to true
        analyseTracks()
    end setMetaData_

    -- app handlers -----------------------------------------------------------------------------------------------------
	on applicationWillFinishLaunching_(aNotification)
		-- Insert code here to initialize your application before any files are opened
        set tempDir to (path to temporary items from user domain) as text
        tell current application's NSImage
            set my notfoundImg to imageNamed_("no_image_found.jpg")
            set my multiImg to imageNamed_("multicds.jpg")            
        end tell
        multiImg's setSize_({128, 128})
        set iTListener to current application's iTunesListener's alloc's init()
        iTListener's startListening_(me)
        analyseTracks()
	end applicationWillFinishLaunching_

	on applicationShouldTerminate_(sender)
		-- Insert code here to do any housekeeping before your application quits
        iTListener's stopListening()
		return current application's NSTerminateNow
	end applicationShouldTerminate_

end script


