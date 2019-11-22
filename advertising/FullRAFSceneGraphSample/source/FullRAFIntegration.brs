' ********** Copyright 2016 Roku Corp.  All Rights Reserved. ********** 

'A full RAF integration Example:
' - Include RAF.
' - setAdURL to set the ad URL.
' - Examples of RAF MACROS being passed in the ad call.
' - getAds() for VAST parsing.
' - showAds for rendering.
' - Enable Nielsen.
' - Pass all parameters to Nielsen beacons with examples of genre, program id and content.
'@param videoContent [AA] object that has valid data for playing video with roVideoScreen.
Sub PlayContentWithFullRAFIntegration()
    adIface = Roku_Ads() 'RAF initialize
    print "Roku_Ads library version: " + adIface.getLibVersion()

    adIface.setDebugOutput(true) 'for debug pupropse

    'RAF content params
    adIface.setContentId(m.videoContent.contentId)
    adIface.SetContentGenre(m.videoContent.contentGenre)
    
    'Nielsen content params
    adIface.enableNielsenDAR(true)
    adIface.setContentLength(m.videoContent.conntentLength)
    adIface.setNielsenProgramId(m.videoContent.nielsenProgramId)
    adIface.setNielsenGenre(m.videoContent.nielsenGenre)
    adIface.setNielsenAppId(m.videoContent.nielsenAppId)

    'Indicates whether the default Roku backfill ad service URL 
    'should be used in case the client-configured URL fails (2 retries)
    'to return any renderable ads.
    adIface.setAdPrefs(true, 2)

    ' Normally, would set publisher's ad URL here.  Uncomment following line to do so.
    ' adIface.setAdUrl(m.videoContent.adUrl) 
    ' Otherwise uses default Roku ad server (with single preroll placeholder ad)

    'Returns available ad pod(s) scheduled for rendering or invalid, if none are available.
    adPods = adIface.getAds()

    playContent = true
    'render pre-roll ads
    if adPods <> invalid and adPods.count() > 0 then
        playContent = adIface.showAds(adPods)
    endif

    m.loading.visible = false
    if playContent then 
        m.video.visible = true
        m.video.setFocus(true)
        m.video.control = "play"
    else
        m.list.visible = true
        m.list.setFocus(true)
        return
    end if

     while(true)
        msg = wait(0, m.port)
        msgType = type(msg)

        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed() then return
        else if msgType = "roSGNodeEvent"
           if (msg.GetNode() = "MainVideo")

                if msg.GetField() = "position" then
                    'render mid-roll ads
                    curPos = m.video.position
                    videoEvent = createPlayPosMsg(curPos)
                    adPods = adIface.getAds(videoEvent)
                    if adPods <> invalid and adPods.count() > 0
                        m.video.control = "stop"
                        playContent = adIface.showAds(adPods)
                    if playContent then
                            m.video.seek = curPos
                            m.video.control = "play"
                        endif
                    endif
                else if msg.GetField() = "state" then
                    curState = m.video.state
                    if curState = "finished" then
                        'render post-roll ads
                        videoEvent = createPlayPosMsg(curPos, true)
                        adPods = adIface.getAds(videoEvent)
                        m.video.control = "stop"
                        if adPods <> invalid and adPods.count() > 0
                            adIface.showAds(adPods)
                        end if
                        exit while
                    endif
                else if msg.GetField() = "navBack" then
                    'back button handling
                    if msg.GetData() = true then
                        m.video.control = "stop"
                        exit while
                    endif
                end if
            end if

        end if
    end while

End Sub
