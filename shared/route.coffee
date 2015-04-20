
Router.map ->
	this.route "CreatePoll", path: "/" # default landing page is for creating a new poll

	this.route "Polls", # list all the polls
		waitOn: ->
			Meteor.subscribe "polls"
		data: ->
			if this.ready()
				polls = for poll in poll_collection.find().fetch()
					poll.total_votes = poll.options.map((option)->option.votes).reduce((t,s)->t+s)
					poll
				console.log polls
				polls: polls
				
	this.route "Vote", # show details about a single poll
		path: "/vote/:_id"
		loadingTemplate: "loading"
		waitOn: ->
			[Meteor.subscribe("poll", this.params._id), Meteor.subscribe("users")]
		data: ->
			if this.ready()
				poll = poll_collection.findOne(this.params._id)
				# => needed to maintain 'this'
				poll: -> poll
				username: -> Meteor.users.findOne(poll.user_id)?.username or "anonymous"

	this.route "Results",
		path: "/results/:_id"
		loadingTemplate: "loading"
		waitOn: ->
			[Meteor.subscribe("poll", this.params._id), Meteor.subscribe("users")]
		data: ->
			if this.ready
				poll = poll_collection.findOne(this.params._id)

				# => needed to maintain 'this'
				poll: -> poll
				username: -> Meteor.users.findOne(poll.user_id)?.username or "anonymous"
