
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
		form.submit((event)->
			poll_name = $("#poll_name").val()
			polls.insert name: poll_name
			console.log "Polls count: " + polls.find().count()
			event.preventDefault())

	Template.polls.helpers polls: polls.find()
		
		 
	Template.poll.events
		"click .remove": -> polls.remove @_id
		
	# Create local collection to stop options
	new_poll_options = new Meteor.Collection()
	new_poll_options.insert(blank: true)
	new_poll_options.insert(blank: true)
	new_poll_options.insert(blank: true)
	new_poll_options.insert(blank: true)

	Template.CreatePoll.helpers options: new_poll_options.find()


	Template.CreatePollOption.events
		"keyup .poll_option": (event)->
			text = event.target.value 
			new_poll_options.update @_id, value: text, blank: text == ""
			# if text == ""
			# 	new_poll_options.update @_id, value: "", blank: true
			# else
			# 	new_poll_options.update @_id, value:
			if new_poll_options.find(blank: true).count() == 0
				new_poll_options.insert(blank: true)
				
	
	
if Meteor.isServer
	Meteor.startup ->
			
    	