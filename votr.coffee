

NEW_POLL_DEFAULT_OPTIONS = 4

polls = new Mongo.Collection "polls"
poll_options_collection = new Mongo.Collection "poll options"


Router.map ->
	this.route "CreatePoll", path: "/" # default landing page is for creating a new poll
	this.route "Polls", # list all the polls
		waitOn: ->
			Meteor.subscribe "mypolls", Meteor.userId()
	this.route "Vote", # show details about a single poll
		path: "/vote/:_id"
		loadingTemplate: "loading"
		waitOn: ->
			[Meteor.subscribe("poll", this.params._id), Meteor.subscribe("poll_options", this.params._id), Meteor.subscribe("users")]
		data: ->
			if this.ready()
				poll = polls.findOne(this.params._id)
				
				# => needed to maintain 'this'
				poll_options: => poll_options_collection.find(poll: this.params._id)
				poll: -> poll
				username: -> Meteor.users.findOne(poll.user_id)?.username or "anonymous"

	this.route "Results",
		path: "/results/:_id"
		loadingTemplate: "loading"
		waitOn: ->
			[Meteor.subscribe("poll", this.params._id), Meteor.subscribe("poll_options", this.params._id), Meteor.subscribe("users")]
		data: ->
			if this.ready
				poll = polls.findOne(this.params._id)

				# => needed to maintain 'this'
				poll_options: => poll_options_collection.find poll: this.params._id
				poll: -> poll
				username: -> Meteor.users.findOne(poll.user_id)?.username or "anonymous"

if Meteor.isClient

	# make it so the database handles are available in the browser console
	# because coffeescript hides variables outside their scope
	window.polls = polls
	window.poll_options = poll_options_collection
	window.users = Meteor.users


	Template.Polls.helpers
		anonymous: -> Meteor.userId() == null
		polls: -> polls.find()
		empty_poll_list: -> polls.find().count() == 0
		
	Template.PollSummary.events
		"click .remove": -> polls.remove @_id if confirm "This poll is about to be deleted"


	# This code should be moved into something that only happens when showing the template
	#   for creating a new poll, but I'm not sure how to do that yet
	# Create local collection to stop options
	new_poll_options = new Meteor.Collection(null)
	new_poll_options.insert(blank: true) for x in [0...NEW_POLL_DEFAULT_OPTIONS]

	Template.CreatePoll.helpers 
		options: -> new_poll_options.find()
		poll_link: -> Router.path "Vote", _id: Session.get "poll_id"

	Template.CreatePoll.events
		"submit #create_poll": (event)->
			event.preventDefault()
			
			poll_name = $("#poll_name").val()
			
			options = ({value: option.value} for option in new_poll_options.find().fetch())
				
			Meteor.call "create_poll", poll_name, options, (error, result)->
				Session.set "poll_id", result unless error
				alert error if error
				
	
			new_poll_options.find().forEach (option)-> new_poll_options.remove option._id
			new_poll_options.insert(blank: true) for x in [0...NEW_POLL_DEFAULT_OPTIONS] # copied code from above - move to function			

			$("#poll_created").toggle()


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
			
			options = []
			selected_options.each (index, option)->
				options.push {id: $(option).val()}

			Meteor.call "vote", options
			Router.go "Results", _id: this.poll()._id
		
		
	# update pie chart with contents of cursor parameter
	update_results_graph = (cursor)->
		canvas = $("canvas")[0]
		ctx = canvas?.getContext "2d"

		# this is ok, it will be called again
		unless ctx
			return
			

		window.ctx = ctx
	
		data_total = cursor.fetch().map((option)->option.votes).reduce (t,s)->t+s
		
		previous_sum = 0
		
		# this should all be parameterized to make this more useful
		center_x = 50
		center_y = 50
		radius = 45


		# skip options with no votes so it doesn't draw radius lines for them
		for option in cursor.fetch() when option.votes != 0

			value = option.votes
			# if value == 0 then continue
			
			start_percent = previous_sum / data_total
			finish_percent = (previous_sum + value) / data_total

			start_radians = start_percent * 2 * Math.PI
			end_radians = finish_percent * 2 * Math.PI

			ctx.beginPath()
			# if there's only one option, don't draw radius lines, just a full circle
			if value == data_total
				ctx.moveTo(center_x + radius, center_y)
			else
				ctx.moveTo(center_x, center_y)
			ctx.arc(center_x, center_y, radius, start_radians, end_radians)
			ctx.closePath()

			ctx.fillStyle = '#'+Math.floor(Math.random()*16777215).toString(16)
			ctx.fill()


			ctx.lineWidth = 3;
			# ctx.strokeStyle = '#'+Math.floor(Math.random()*16777215).toString(16)
			ctx.stroke()


			previous_sum += value
	
		
	# set up a callback when the canvas template is rendered to keep pie chart up-to-date	
	Template.canvas.rendered = ->
		
		update_results_graph poll_options_collection.find()
		# when poll_options change, update the pie chart
		poll_options_collection.find().observe
			changed: ->
				update_results_graph poll_options_collection.find()
		
	# boilerplate to use username instead of email
	Accounts.ui.config
	  passwordSignupFields: "USERNAME_ONLY"
	

Meteor.methods
	create_poll: (poll_name, options)->
		
		# Insert new poll
		new_poll_id = polls.insert 
			name: poll_name
			user_id: @userId
			
		
		options.map (option)-> 
			poll_options_collection.insert {poll: new_poll_id, value: option.value, votes: 0} if option.value
		
		new_poll_id
		
	
	vote: (options)->
		ids = options.map (option)->option.id
		poll_options_collection.update {_id: {$in: ids}},
			{$inc: {votes: 1}},
			{multi: true}
		

if Meteor.isServer
	
	# get all polls
	Meteor.publish "polls", ->
		polls.find()
		
	Meteor.publish "mypolls", (user_id)->
		polls.find(user_id: user_id)
		
	# get a single poll
	Meteor.publish "poll", (poll_id)->
		polls.find(poll_id)
		
	# get all poll options for a single poll
	Meteor.publish "poll_options", (poll_id)->
		poll_options_collection.find(poll: poll_id)
		
	Meteor.publish "users", ->
		Meteor.users.find()
	
	Meteor.startup ->
		Meteor.users.update {username: 'xaxxon'}, {$set: {god: true}}
			
    	
