

NEW_POLL_DEFAULT_OPTIONS = 4

polls = new Mongo.Collection "polls"
poll_options = new Mongo.Collection "poll options"


Router.map ->
	this.route "about" # just for testing
	this.route "CreatePoll", path: "/" # default landing page is for creating a new poll
	this.route "polls", # list all the polls
		waitOn: ->
			Meteor.subscribe "polls"
	this.route "test",
		waitOn: ->
			console.log "HI"
			[Meteor.subscribe("polls"), Meteor.subscribe("poll_options")]
		data: -> 
			name: polls.findOne().name
			options: poll_options.findOne(polls.findOne()._id).value
	this.route "Vote", # show details about a single poll
		path: "/vote/:_id"
		loadingTemplate: "about"
		waitOn: ->
			console.log "In waiton" + Meteor.subscribe("polls").ready()
			[Meteor.subscribe("polls"), Meteor.subscribe("poll_options")]
		data: ->		
			if this.ready()	
				id: this.params._id
				poll_options: poll_options.find(poll: this.params._id) 
				name: polls.findOne(this.params._id).name

	this.route "Results",
		path: "/results/:_id"
		waitOn: -> 
			[Meteor.subscribe("polls"), Meteor.subscribe("poll_options")]
		data: ->			
			if this.ready()
				id: this.params._id
				poll_options: poll_options.find(poll: this.params._id) 
				name: polls.findOne(this.params._id).name
		

if Meteor.isClient


	window.polls = polls
	window.poll_options = poll_options


	Template.Polls.helpers
		polls: polls.find()
		
	Template.PollSummary.events
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
							votes: 0
			
			console.log "Before"				
			console.log new_poll_options.find().count()
			new_poll_options.find().forEach (option)-> new_poll_options.remove option._id
			new_poll_options.insert(blank: true) for x in [0...NEW_POLL_DEFAULT_OPTIONS] # copied code from above - move to function
			
			
			console.log "After"
			console.log new_poll_options.find().count()
						
			false
					

	Template.CreatePollOption.events
		"keyup .poll_option": (event)->
			text = event.target.value

			new_poll_options.update @_id, value: text, blank: text == ""

			blank_poll_options = new_poll_options.find blank: true
			console.log "delete me"
			if blank_poll_options.count() == 0
				new_poll_options.insert blank: true 


	Template.Vote.events
		"submit #vote": (event, template)->
			event.preventDefault()
			vote_selected = false
			$(".option:checked").each (index, option)->
				vote_selected = true
				option_id = $(option).val()
				option = poll_options.findOne(option_id)
				votes = option['votes'] or 0
				option['votes'] = votes + 1
				poll_options.update option_id, option
			console.log template.data
			Router.go "Results", _id: template.data.id if vote_selected
			
					
	# Template.PollOptions.helpers
	# 	options: console.log this._id
		
	# Template.PollOptions.events
	# 	"change .option": (event)->
	# 		# get state of checkbox
	# 		checked = event.target.val()
	# 		poll_options.update @_id


if Meteor.isServer
	
	Meteor.publish "polls", ->
		polls.find()
		
	Meteor.publish "poll_options", ->
		poll_options.find()
	
	Meteor.startup ->
		
			
    	
