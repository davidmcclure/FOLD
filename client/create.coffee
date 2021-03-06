Template.create.rendered = ->
    unless (Session.equals("currentY", undefined) and Session.equals("currentX", undefined))
        $('.attribution, #to-story').fadeOut(1)
        goToY(Session.get("currentY"))
        goToX(Session.get("currentX"))

Template.background_image.helpers 
    backgroundImage: ->
        if @backgroundImage then @backgroundImage
        else Session.get("backgroundImage")

Template.background_image.events
    "click div.save-background-image": ->
        Session.set("backgroundImage", $('input.background-image-input').val())

getSelectionCoords = ->
    sel = document.selection
    range = undefined
    rect = undefined
    x = 0
    y = 0
    if sel
      unless sel.type is "Control"
        range = sel.createRange()
        range.collapse true
        x = range.boundingLeft
        y = range.boundingTop
    else if window.getSelection
      sel = window.getSelection()
      if sel.rangeCount
        range = sel.getRangeAt(0).cloneRange()
        if range.getClientRects
          range.collapse true
          rect = range.getClientRects()[0]
          x = rect.left
          y = rect.top
        
        # Fall back to inserting a temporary element
        if x is 0 and y is 0
          span = document.createElement("span")
          if span.getClientRects
            
            # Ensure span has dimensions and position by
            # adding a zero-width space character
            span.appendChild document.createTextNode("​")
            range.insertNode span
            rect = span.getClientRects()[0]
            x = rect.left
            y = rect.top
            spanParent = span.parentNode
            spanParent.removeChild span
            
            # Glue any broken text nodes back together
            spanParent.normalize()
    res = 
        x: x
        y: y


Template.layout_options.events
    "click i#expand": ->
        narrativeView = Session.get("narrativeView")
        Session.set("narrativeView", !narrativeView)

Template.create.helpers
    narrativeView: -> Session.get("narrativeView")
    category: -> Session.get("storyCategory")

Template.create.events
    "mousedown": ->
        Session.set("formatting", false)
    "mouseup": ->
        if window.getSelection
            text = window.getSelection().toString()
        else if (typeof document.selection and document.selection.type is "Text")
            text = document.selection.createRange().text
        if text
            Session.set("formatting", true)
            console.log "TEXT:", text
            coords = getSelectionCoords()
            Session.set("formattingTop", coords.y)
            Session.set("formattingLeft", coords.x)

Template.formatting.helpers
    top: -> Session.get("formattingTop") - 60
    left: -> Session.get("formattingLeft")

# Template.vertical_narrative.helpers
#     verticalSections: -> Session.get('verticalSections')

#######################
# Adding Sections
#######################
Template.minimized_add_vertical.events
    "click section": ->
        # Append Vertical Section
        verticalSections = Session.get('verticalSections')
        newVerticalSection =
            title: 'Title'
            content: 'Content'
            index: verticalSections.length
        verticalSections.push(newVerticalSection)
        Session.set('verticalSections', verticalSections)

        # Initialize Horizontal Section
        horizontalSections = Session.get('horizontalSections')
        newHorizontalSection =
            data: []
            index: horizontalSections.length
        horizontalSections.push(newHorizontalSection)
        Session.set('horizontalSections', horizontalSections)   

Template.add_vertical.events
    "click section": ->
        # Append Vertical Section
        verticalSections = Session.get('verticalSections')
        newVerticalSection =
            title: 'Title'
            content: 'Content'
            index: verticalSections.length
        verticalSections.push(newVerticalSection)
        Session.set('verticalSections', verticalSections)

        # Initialize Horizontal Section
        horizontalSections = Session.get('horizontalSections')
        newHorizontalSection =
            data: []
            index: horizontalSections.length
        horizontalSections.push(newHorizontalSection)
        Session.set('horizontalSections', horizontalSections)   

Template.add_horizontal.helpers
    left: ->
        width = Session.get "width"
        if width < 1024 then width = 1024
        halfWidth = width / 2
        cardWidth = Session.get "cardWidth"
        halfWidth + (Session.get "separation") / 2

# Template.add_horizontal.events
#     "click section": (d) ->
#         # unless Session.get("editingContext")
#         #     # TODO Make this based on a session variable
#         #     $("section.horizontal-new-section").animate({height: "100%", width: "540px"}, 250)

#         #     # Shift all horizontal sections right
#         #     $("div.horizontal-context section:not(:first)").animate({left: "+=440px"}, 250)

#         #     Session.set("editingContext", true)

#         # Append Horizontal Section to Current Horizontal Context
#         horizontalSections = Session.get('horizontalSections')
#         console.log("horizontalSections", horizontalSections, Session.get('currentVertical'))
#         newHorizontalSection = 
#             if Session.get("horizontalSections")[Session.get('currentVertical')]?.data?.length
#                 x = Session.get("horizontalSections")[Session.get('currentVertical')].data.length
#             else 
#                 x = 0
#             index: x
#         horizontalSections[Session.get('currentVertical')].data.push(newHorizontalSection)
#         Session.set('horizontalSections', horizontalSections)   

renderTemplate = (d, templateName, context) ->
    srcE = if d.srcElement then d.srcElement else d.target
    parentSection = $(srcE).closest('section')
    parentSection.empty()
    if context
        UI.insert(UI.renderWithData(templateName, context), parentSection.get(0))
    else
        UI.insert(UI.render(templateName), parentSection.get(0))

Template.horizontal_context.helpers
    lastUpdate: ->
        Session.get('lastUpdate')
        return

Template.horizontal_context.events
    'click img.text-button': (d) -> renderTemplate(d, Template.create_text_section)
    'click img.photo-button': (d) -> renderTemplate(d, Template.create_image_section)
    'click img.map-button': (d) -> renderTemplate(d, Template.create_map_section)
    'click img.youtube-button': (d) -> renderTemplate(d, Template.create_video_section)
    'click img.gifgif-button': (d) -> renderTemplate(d, Template.create_gifgif_section)
    'click img.audio-button': (d) -> renderTemplate(d, Template.create_audio_section)

Template.create_section_options.events
    "click div#back": (d) ->
        srcE = if d.srcElement then d.srcElement else d.target
        parentSection = $(srcE).closest('section')
        parentSection.empty()
        UI.insert(UI.render(Template.horizontal_section_buttons), parentSection.get(0)) 

Template.create_text_section.events
    "click div#save": (d) ->
        srcE = if d.srcElement then d.srcElement else d.target
        parentSection = $(srcE).closest('section')
        horizontalIndex = parentSection.data('index')
        text = parentSection.find('textarea.text-input').val()

        newDocument =
            type: 'text'
            content: text
            index: horizontalIndex

        # Bind data
        horizontalSections = Session.get('horizontalSections')
        horizontalSections[Session.get('currentVertical')].data[horizontalIndex] = newDocument
        Session.set('horizontalSections', horizontalSections) 

        # Render display section
        context = newDocument 
        renderTemplate(d, Template.display_text_section, context)

Template.create_video_section.events
    "click div#save": (d) ->
        srcE = if d.srcElement then d.srcElement else d.target
        parentSection = $(srcE).closest('section')
        horizontalIndex = parentSection.data('index')
        url = parentSection.find('input.youtube-link-input').val()
        description = parentSection.find('input.youtube-description-input').val()
        newDocument =
            type: 'video'
            url: url
            description: description
            index: horizontalIndex

        # Bind data
        horizontalSections = Session.get('horizontalSections')
        horizontalSections[Session.get('currentVertical')].data[horizontalIndex] = newDocument
        Session.set('horizontalSections', horizontalSections) 

        # Render display section
        context = newDocument 
        renderTemplate(d, Template.display_video_section, context)

Template.create_map_section.events
    "click div#save": (d) ->
        srcE = if d.srcElement then d.srcElement else d.target
        parentSection = $(srcE).closest('section')
        horizontalIndex = parentSection.data('index')
        url = parentSection.find('input.map-url-input').val()
        newDocument =
            type: 'map'
            url: url
            index: horizontalIndex

        # Bind data
        horizontalSections = Session.get('horizontalSections')
        horizontalSections[Session.get('currentVertical')].data[horizontalIndex] = newDocument
        Session.set('horizontalSections', horizontalSections) 

        # Render display section
        context = newDocument 
        renderTemplate(d, Template.display_map_section, context)

Template.create_image_section.events
    "click div#save": (d) ->
        srcE = if d.srcElement then d.srcElement else d.target
        parentSection = $(srcE).closest('section')
        horizontalIndex = parentSection.data('index')
        url = parentSection.find('input.image-url-input').val()
        description = parentSection.find('input.image-description-input').val()

        newDocument =
            type: 'image'
            url: url
            description: description
            index: horizontalIndex

        # Bind data
        horizontalSections = Session.get('horizontalSections')
        horizontalSections[Session.get('currentVertical')].data[horizontalIndex] = newDocument
        Session.set('horizontalSections', horizontalSections) 

        # Render display section
        context = newDocument 
        renderTemplate(d, Template.display_image_section, context)


# TODO Don't put in so much duplicated code!!!
Template.horizontal_section_block.events
    "click div#delete": (d) -> 
        console.log("delete")
        srcE = if d.srcElement then d.srcElement else d.target
        parentSection = $(srcE).closest('section')
        horizontalIndex = parentSection.data('index')
        horizontalSections = Session.get('horizontalSections')
        horizontalSections[Session.get('currentVertical')].data.splice(horizontalIndex, 1)
        Session.set('horizontalSections', horizontalSections)  

    "click div#edit": (d) ->
        srcE = if d.srcElement then d.srcElement else d.target
        parentSection = $(srcE).closest('section')
        horizontalIndex = parentSection.data('index')
        horizontalSections = Session.get('horizontalSections')
        section = horizontalSections[Session.get('currentVertical')].data[horizontalIndex]
        data = section
        type = section.type
        switch type
            when "text" then renderTemplate(d, Template.create_text_section, section)
            when "image" then renderTemplate(d, Template.create_image_section, section)
            when "map" then renderTemplate(d, Template.create_map_section, section)


#######################
# Save and Publish
#######################
Template.create_options.events
    "click div#save": ->
        console.log("SAVE")
        # Get all necessary fields
        storyTitle = $.trim($('div.title-author div.title').text())
        storyDashTitle = storyTitle.toLowerCase().split(' ').join('-')

        backgroundImage = Session.get("backgroundImage")
        date = new Date()
        user = Meteor.user()._id
        verticalSections = []
        $('section.vertical-narrative-section').each((i) ->
            title = $.trim($(this).find('div.title').text())
            content = $.trim($(this).find('div.content').text())
            verticalSections.push(
                index: i
                title: title
                content: content
                )
            )
        horizontalSections = Session.get('horizontalSections')

        storyDocument =
            title: storyTitle
            backgroundImage: backgroundImage
            storyDashTitle: storyDashTitle
            verticalSections: verticalSections
            horizontalSections: horizontalSections
            userId: user
            lastSaved: date

        console.log(storyDocument)

        Session.set("storyDashTitle", storyDashTitle)
        storyId = Stories.findOne(storyDashTitle: storyDashTitle)?._id
        unless storyId
            storyId = Session.get("storyId")
        console.log("ID", storyId)
        if storyId
            Stories.update({_id: storyId}, {$set: storyDocument})
        else
            storyId = Stories.insert(storyDocument)
            Session.set("storyId", storyId)

    "click div#delete": ->
        storyId = Session.get('storyId')
        if storyId
            Stories.remove({_id: storyId})
        Router.go('home')

    "click div#publish": ->   
        console.log("PUBLISH")
        storyDashTitle = Session.get("storyDashTitle")
        storyId = Stories.findOne(storyDashTitle: storyDashTitle)?._id
        unless storyId
            storyId = Session.get("storyId")
        if storyId
            Stories.update({_id: storyId}, {$set: {published: true, publishDate: new Date()}})
