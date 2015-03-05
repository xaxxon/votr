

NEW_POLL_DEFAULT_OPTIONS = 4

polls = new Mongo.Collection("polls")
poll_options = new Mongo.Collection "poll options"


Router.map ->
	this.route "about"
	this.route "create_poll", path: "/"
	this.route "polls"
	this.route "PollDetails",
		path: "/poll/:_id"
		data: ->
			polls.findOne this.params._id
		

if Meteor.isClient

	# On ready javascript
	jQuery ->
		# empty for now, using meteor events wherever possible
		
		
	window.polls = polls
	window.poll_options = poll_options


	Template.polls.helpers
		polls: polls.find()
		
	Template.poll.events
		"click .remove": -> polls.remove @_id

	# Create local collection to stop options
	new_poll_options = new Meteor.Collection(null)
	new_poll_options.insert(blank: true) for x in [0...NEW_POLL_DEFAULT_OPTIONS]

	Template.CreatePoll.helpers options: new_poll_options.find()

	Template.CreatePoll.events
		"submit #create_poll": (event)->
			console.log "This is: "
			console.log this
			console.log "meteor submit event triggered with poll name:"
			poll_name = $("#poll_name").val()
			console.log poll_name
			new_poll_id = polls.insert name: poll_name
			console.log "new poll id: " + new_poll_id
			
			
			console.log "here1"
			new_poll_options.find().forEach	do (new_poll_id) ->
				(thing) ->
					console.log "here3"
					console.log "adding: " + thing['value'] unless thing["blank"]
					console.log "to poll " + new_poll_id
					unless thing["blank"]
						poll_options.insert 
							poll: new_poll_id
							value: thing['value'] 
			false
					

	Template.CreatePollOption.events
		"keyup .poll_option": (event)->
			text = event.target.value

			new_poll_options.update @_id, value: text, blank: text == ""

			blank_poll_options = new_poll_options.find blank: true

			if blank_poll_options.count() == 0
				new_poll_options.insert blank: true 



	Template.PollDetails.helpers
		
		poll_options: -> poll_options.find( )
	


	Template.PollOptions.helpers
		options: console.log this._id



if Meteor.isServer
	Meteor.startup ->
			
    	
