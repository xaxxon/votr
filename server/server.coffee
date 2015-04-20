
Meteor.methods

	# options is an array of objects with the 'value' key set to the name of the poll option
	create_poll: (name, options)->
		for option in options
			option.votes = 0
			# assign a unique key to allow multiple options with the same name
			option.id = new Mongo.ObjectID()._str		

		new_poll_id = poll_collection.insert
			name: name
			options: options

		new_poll_id


	vote: (poll_id, options)->

		for option in options
			console.log "Poll id: #{poll_id}"
			console.log "Option id: #{option.id}"
			poll_collection.update(
				{_id: poll_id, 'options.id': option.id}
				{$inc: {'options.$.votes': 1}}
				{}
				(error, update_count)->
					console.log "ERROR #{error}" if error
					console.log "updated #{update_count} records" unless error)


	remove_poll: (poll_id)->
		console.log "about to delete #{poll_id}"
		poll = poll_collection.findOne(poll_id) 
		console.log poll
		if poll
			god = Meteor.users.findOne(@userId)?.god
			
			console.log "userid: #{@userId} poll owner: #{poll.owner}"
		
			# check to make sure the user either owns the poll or is god
			poll_collection.remove(id) if god or @userId == poll.owner


isGod = (user_id)->
	Meteor.users.findOne(user_id)?.god
		
# retrieve a user's polls or all polls if god - not for security, just for convenience
#   since anyone is allowed to vote on any poll
Meteor.publish "polls", ->
	if isGod @userId
		console.log "allowing access to all polls"
		poll_collection.find()
	else
		console.log "allowing access to polls created by #{@userId}"
		poll_collection.find(user_id: @userId) 
	
# get a single poll
Meteor.publish "poll", (poll_id)->
	poll_collection.find(poll_id)
	
Meteor.publish "users", ->
	Meteor.users.find()

Meteor.startup ->
	Meteor.users.update {username: 'admin'}, {$set: {god: true}}
		
	poll_collection.before.insert (userId, poll)->
	  poll.createdAt = Date.now()
	  poll.creator_id = userId
  
# http://docs.meteor.com/#/full/accounts_validatenewuser
# how to fail new user creation (or return false)
# throw new Meteor.Error(403, "Message");
Accounts.validateNewUser (user)->
	console.log "validateNewUser"
	console.log user
	throw new Meteor.Error 403, "Username may not be 'b'" if user.username == 'b'
