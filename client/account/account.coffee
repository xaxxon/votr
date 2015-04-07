
if Meteor.isClient		
		
	Template.Login.events =
		'submit #login': (event, template)->
			event.preventDefault()
			username = $('#login_username').val()
			password = $('#login_password').val()
			Meteor.loginWithPassword username, password, (result)-> 
				if result
					console.log "check console for login failure info"; 
					console.log result
				else
					account_set_action_display ACCOUNT_ACTIONS.Status
			
		'click #account_switch_to_create_user': (event, template)->
				account_set_action_display ACCOUNT_ACTIONS.CreateUser
			
	Template.CreateUser.events =
		'submit #create_user': (event, template)->
			event.preventDefault()
			
			username = $('#create_user_username').val()
			password = $('#create_user_password').val()
			confirm_password = $('create_user_confirm_password').val()
			console.log "not checking password match yet: #{username} #{password}"
			# one of: username, email
			# password
			Accounts.createUser
				username: username
				password: password
				(result)-> console.log "check console for create user result"; console.log result
				
		'click #account_switch_to_login': (event, template)->
			account_set_action_display ACCOUNT_ACTIONS.Login
			
	Template.Account.events =
		'click #sign_in': (event, template)->
			account_set_action_display ACCOUNT_ACTIONS.Login
			
		'click #log_out': (event, template)->
			console.log "logging out user"
			Meteor.logout()

	Template.AccountCancel.events =
		'click #account_cancel': (event, template)->
			account_set_action_display ACCOUNT_ACTIONS.Status
			
			
ACCOUNT_ACTIONS = 
	Status: 1
	Login: 2
	CreateUser: 3
	
account_set_action_display = (action)->
	switch action
		when ACCOUNT_ACTIONS.Status
			$('#status').show()
			$('#login').hide()
			$('#create_user').hide()
			
		when ACCOUNT_ACTIONS.Login
			$('#status').hide()
			$('#login').show()
			$('#create_user').hide()
			
		when ACCOUNT_ACTIONS.CreateUser
			$('#status').hide()
			$('#login').hide()
			$('#create_user').show()
			
	