

NEW_POLL_DEFAULT_OPTIONS = 4

polls = new Mongo.Collection("polls")


Router.map ->
	this.route "about"
	this.route "create_poll", path: "/"
	this.route "polls"
		

if Meteor.isClient

	# On ready javascript
	jQuery ->
    window.polls = polls
		form = $("#create_poll")
		form.submit (event)->
			event.preventDefault()
			poll_name = $("#poll_name").val()
			polls.insert name: poll_name
			console.log "Polls count: " + polls.find().count()
			poll_options = new Mongo.Collection "poll options"

			new_poll_options.find().forEach( (thing)->
			    poll_options.insert({poll: @_id, value: thing['value']}) unless thing[blank]  )


	Template.polls.helpers polls: polls.find()
	Template.poll.events
		"click .remove": -> polls.remove @_id

	# Create local collection to stop options
	new_poll_options = new Meteor.Collection(null)
	new_poll_options.insert(blank: true) for x in [0...NEW_POLL_DEFAULT_OPTIONS]

	Template.CreatePoll.helpers options: new_poll_options.find()


  Template.CreatePollOption.events
    "keyup .poll_option": (event)->
      alert("FUCK2")
      text = event.target.value
      new_poll_options.update @_id, value: text, blank: if text == ""

      blank_poll_options = new_poll_options.find blank:true

      if blank_poll_options.count() == 0
        new_poll_options.insert blank: true 


  

if Meteor.isServer
	Meteor.startup ->
			
    	
