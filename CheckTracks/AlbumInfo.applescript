--AlbumInfo class

script AlbumInfo
    property parent : class "NSObject"
    property albumTitle : ""
    property albumArtist : ""
    property albumType : "" -- CD, DVD, LP
    property albumGenre : ""
    property albumSummary : ""
    property releaseYear : ""
    property country : ""
    property trackCount : 0
    property discCount : 0
    property thumbURL : ""
    property coverURL : ""
    property albumID : ""
    
    on createSummary()
        set albumSummary to ""
        if not albumArtist = "" then set albumSummary to albumArtist as string
        if length of albumSummary > 30 then
            set albumSummary to text from 1 to 30 of albumSummary & "..."
        end if
        if albumSummary = "" then
            set albumSummary to albumTitle as string
        else
            if not albumTitle = "" then set albumSummary to albumSummary & " - " & albumTitle as string
        end if
        if length of albumSummary > 65 then
            set albumSummary to text from 1 to 65 of albumSummary & "..."
        end if
        set albumSummary to albumSummary & ";"
        if not albumType = "" then set albumSummary to albumSummary & " " & albumType as string
        if not country = "" then set albumSummary to albumSummary & " " & country as string
        if not releaseYear = "" then set albumSummary to albumSummary & " " & releaseYear as string
        if trackCount as integer > 0 then set albumSummary to albumSummary & " | " & trackCount as string & " tracks"
        if discCount as integer > 1 then set albumSummary to albumSummary & " on " & discCount as string & "discs"
    end createSummary
    
end script