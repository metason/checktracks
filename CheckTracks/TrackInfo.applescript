--TrackInfo class

script TrackInfo
    property parent : class "NSObject"
    property trackNo : 0
    property trackName : ""
    property trackArtist : ""
    property trackComposer : ""
    property trackComment : ""
    property trackDiscNo : ""
    property trackDiscCount : ""
    
    on setTrackNo_(newVal)
        if newVal = missing value then set newVal to 0
        set my trackNo to newVal as integer
    end setTrackNo_
    
end script