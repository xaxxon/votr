


Template.PollSummary.events
	"click .remove": -> Meteor.call "remove_poll", @_id if confirm "This poll is about to be deleted"
	

# Create local collection to store options
Template.CreatePoll.options = new Meteor.Collection(null)

Template.CreatePoll.helpers 
	poll_link: -> Router.path "Vote", _id: Session.get "poll_id"
	options: -> 
		Template.CreatePoll.options.remove {}
		Template.CreatePoll.options.insert(blank: true) for x in [0...4]
		Template.CreatePoll.options.find()

Template.CreatePoll.events
	"submit #create_poll": (event, data)->
		event.preventDefault()

		poll_name = $("#poll_name").val()
		options = ({value: option.value} for option in Template.CreatePoll.options.find().fetch() when !option.blank )
			
		Meteor.call "create_poll", poll_name, options, (error, result)->
			Session.set "poll_id", result unless error
			alert error if error

		$("#poll_created").toggle()


Template.CreatePollOption.events
	# Whenever a key is pressed, check to make sure another slot doesn't needed to be added
	"keyup .poll_option": (event, test)->
		text = event.target.value

		Template.CreatePoll.options.update @_id, {value: text}

		# # If there are no blank slots remaining, add another one at the bottom
		blank_poll_options = Template.CreatePoll.options.find blank: true
		if blank_poll_options.count() == 0
			Template.CreatePoll.options.insert blank: true
		
			


Template.Vote.events
	"submit #vote": (event)->
		event.preventDefault()
		selected_options = $(".option:checked")
		
		# if nothing is selected, don't do anything
		if selected_options.length == 0
			alert "You must select an option in order to vote" 
			return 
		
		options = []
		selected_options.each (index, option)->
			options.push {id: $(option).val()}

		Meteor.call "vote", this.poll()._id, options
		Router.go "Results", _id: this.poll()._id
		
		
		
# set up a callback when the canvas template is rendered to keep pie chart up-to-date	
Template.canvas.rendered = ->
	pie = new PieChart $('#results_pie_chart')[0]
	pie.update_results_graph poll_collection.findOne().options.map (option)->{name: option.value, value: option.votes}
	
	# when poll_options change, update the pie chart
	poll_collection.find().observe
		changed: ->
			pie.update_results_graph poll_collection.findOne().options.map (option)->{name: option.value, value: option.votes}
		

