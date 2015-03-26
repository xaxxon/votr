

NEW_POLL_DEFAULT_OPTIONS = 4

polls = new Mongo.Collection "polls"
poll_options = new Mongo.Collection "poll options"


Router.map ->
	this.route "CreatePoll", path: "/" # default landing page is for creating a new poll
	this.route "Polls", # list all the polls
		waitOn: ->
			Meteor.subscribe "polls"
	this.route "Vote", # show details about a single poll
		path: "/vote/:_id"
		loadingTemplate: "about"
		waitOn: ->
			console.log "In waiton" + Meteor.subscribe("polls").ready()
			[Meteor.subscribe("poll", this.params._id), Meteor.subscribe("poll_options", this.params._id)]
		data: ->		
			if this.ready()	
				id: this.params._id
				poll_options: poll_options.find(poll: this.params._id) 
				name: polls.findOne(this.params._id).name

	this.route "Results",
		path: "/results/:_id"
		waitOn: -> 
			[Meteor.subscribe("poll", this.params._id), Meteor.subscribe("poll_options", this.params._id)]
		data: ->			
			if this.ready()
				id: this.params._id
				poll_options: poll_options.find(poll: this.params._id) 
				name: polls.findOne(this.params._id).name
		

if Meteor.isClient

	# make it so the database handles are available in the browser console
	# because coffeescript hides variables outside their scope
	window.polls = polls
	window.poll_options = poll_options


	Template.Polls.helpers
		polls: polls.find()
		
	Template.PollSummary.events
		"click .remove": -> polls.remove @_id if confirm "This poll is about to be deleted"


	# This code should be moved into something that only happens when showing the template
	#   for creating a new poll, but I'm not sure how to do that yet
	# Create local collection to stop options
	new_poll_options = new Meteor.Collection(null)
	new_poll_options.insert(blank: true) for x in [0...NEW_POLL_DEFAULT_OPTIONS]

	Template.CreatePoll.helpers options: new_poll_options.find()

	Template.CreatePoll.events
		"submit #create_poll": (event)->
			event.preventDefault()
			
			poll_name = $("#poll_name").val()
			new_poll_id = polls.insert name: poll_name
			
			new_poll_options.find().forEach	do (new_poll_id) ->
				(thing) ->
					unless thing["blank"]
						poll_options.insert 
							poll: new_poll_id
							value: thing['value'] 
							votes: 0
			
			new_poll_options.find().forEach (option)-> new_poll_options.remove option._id
			new_poll_options.insert(blank: true) for x in [0...NEW_POLL_DEFAULT_OPTIONS] # copied code from above - move to function						
					

	Template.CreatePollOption.events
		# Whenever a key is pressed, check to make sure another slot doesn't needed to be added
		"keyup .poll_option": (event)->
			text = event.target.value

			new_poll_options.update @_id, value: text, blank: text == ""

			# If there are no blank slots remaining, add another one at the bottom
			blank_poll_options = new_poll_options.find blank: true
			if blank_poll_options.count() == 0
				new_poll_options.insert blank: true 


	Template.Vote.events
		"submit #vote": (event, template)->
			event.preventDefault()
			selected_options = $(".option:checked")
			
			# if nothing is selected, don't do anything
			if selected_options.length == 0
				alert "You must select an option in order to vote" 
				return 
			
			vote_selected = false
			selected_options.each (index, option)->
				vote_selected = true
				option_id = $(option).val()
				option = poll_options.findOne(option_id)
				votes = option['votes'] or 0
				option['votes'] = votes + 1
				poll_options.update option_id, option
			console.log template.data
			Router.go "Results", _id: template.data.id if vote_selected
		
		
		
	update_results_graph = (cursor)->
		canvas = $("canvas")[0]
		ctx = canvas.getContext "2d"
		window.ctx = ctx
	
		data_total = cursor.fetch().map((option)->option.votes).reduce (t,s)->t+s
		console.log "data total " + data_total
		
		previous_sum = 0
		
		# this should all be parameterized to make this more useful
		center_x = 50
		center_y = 50
		radius = 45


		# skip options with no votes so it doesn't draw radius lines for them
		for option in cursor.fetch() when option.votes != 0

			console.log "In foreach"
			value = option.votes
			# if value == 0 then continue
			
			start_percent = previous_sum / data_total
			finish_percent = (previous_sum + value) / data_total

			start_radians = start_percent * 2 * Math.PI
			end_radians = finish_percent * 2 * Math.PI

			console.log "start/stop radians: " + start_radians + " : " + end_radians

			ctx.beginPath()
			# if there's only one option, don't draw radius lines, just a full circle
			if value == data_total
				console.log "Full circle"
				ctx.moveTo(center_x + radius, center_y)
			else
				console.log 'partial circle ' + value + " / " + data_total
				ctx.moveTo(center_x, center_y)
				
			ctx.arc(center_x, center_y, radius, start_radians, end_radians)
			ctx.closePath()

			ctx.fillStyle = '#'+Math.floor(Math.random()*16777215).toString(16)
			ctx.fill()


			ctx.lineWidth = 3;
			# ctx.strokeStyle = '#'+Math.floor(Math.random()*16777215).toString(16)
			ctx.stroke()


			previous_sum += value
	
		
					
	Template.canvas.rendered = ->
		
		update_results_graph poll_options.find()
		poll_options.find().observe
			changed: ->
				update_results_graph poll_options.find()
		


if Meteor.isServer
	
	# get all polls
	Meteor.publish "polls", ->
		polls.find()
		
	# get a single poll
	Meteor.publish "poll", (poll_id)->
		console.log poll_id
		polls.find(poll_id)
		
	# get all poll options for a single poll
	Meteor.publish "poll_options", (poll_id)->
		poll_options.find(poll: poll_id)
	
	Meteor.startup ->
		
			
    	
