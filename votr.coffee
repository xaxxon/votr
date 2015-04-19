




if Meteor.isClient

	# getting distinct colors is actually a fairly complex thing, simple euclidian distance isn't good enough.
	#   There's a bunch of good links here: http://stackoverflow.com/questions/13586999/color-difference-similarity-between-two-values-with-js
	get_random_color = ->
		red = Math.floor(Math.random() * 256);
		green = Math.floor(Math.random() * 256);
		blue = Math.floor(Math.random() * 256);
		
		# check colors to see if we're not too close
		# color = "rgb(#{red}#,#{green},#{blue})"
		# console.log color
		# color
		[red, green, blue]
		
	colors = []
	minimum_delta_e = 30
	delta_e = new DeltaE()
	max_attempts = 100
	
	# This is the bogosort of good color finders
	get_distinct_color = ->
		attempts = 0
		# store a decent color just in case - not too close to neighbor
		worst_case_color = false
		loop
			rgb = get_random_color()
			if ++attempts > max_attempts or colors.length == 0
				console.log "FAILED to find a distinct color but WCC: #{worst_case_color}" unless colors.length == 0
				rgb = worst_case_color or rgb
				colors.push rgb
				return "rgb(#{rgb[0]},#{rgb[1]},#{rgb[2]})" 
			
			found_another_color_too_close = false
			for color in colors 
				# have to make it easier as more colors are added or they will all fail the test for higher delta-e's
				if (de = delta_e.getDeltaE00FromRGB(rgb, color)) < minimum_delta_e - colors.length / 2
					found_another_color_too_close = true
					worst_case_color = rgb if delta_e.getDeltaE00FromRGB(rgb, colors[-1..][0]) > minimum_delta_e
					break
			
			unless found_another_color_too_close
				colors.push rgb
				return "rgb(#{rgb[0]},#{rgb[1]},#{rgb[2]})"
			

		
	# update pie chart with contents of cursor parameter
	update_results_graph = (cursor)->
		stage = new Kinetic.Stage
			container: 'results-pie-chart'
			height: 300
			width: 300
		layer = new Kinetic.Layer()
	
		data_total = cursor.fetch().map((option)->option.votes).reduce (t,s)->t+s
		
		previous_sum = 0
		
		# this should all be parameterized to make this more useful
		center_x = 105
		center_y = 105
		radius = 70


		# skip options with no votes so it doesn't draw radius lines for them
		for option in cursor.fetch() when option.votes != 0

			value = option.votes
			# if value == 0 then continue
			
			start_percent = previous_sum / data_total
			finish_percent = (previous_sum + value) / data_total

			start_radians = start_percent * 2 * Math.PI
			end_radians = finish_percent * 2 * Math.PI
			
			degrees = value / data_total * 360
			rotation = previous_sum / data_total * 360

			wedge = new Kinetic.Wedge
		        x: stage.width() / 2
		        y: stage.height() / 2
		        radius: radius
		        angle: degrees
		        fill: get_distinct_color()
		        stroke: 'black'
		        strokeWidth: 4
		        rotation: rotation
				
			do (wedge)->
				wedge.on 'mouseenter', ->
					@animation?.stop() # stop the previous animation if it exists
					@animation = new Kinetic.Animation wedge_animator({wedge: wedge, start_radius: wedge.getRadius(), end_radius: 90, duration: 250}), layer
					@animation.start()
		
		
			do (wedge)->
				wedge.on 'mouseleave', ->
					@animation?.stop() # stop the previous animation if it exists
					@animation = new Kinetic.Animation wedge_animator({wedge: wedge, start_radius: wedge.getRadius(), end_radius: radius, duration: 250}), layer
					@animation.start()	
			

			layer.add wedge
			

			previous_sum += value

		stage.add layer
	
	
	
	# takes parameters:
	#   wedge
	#   start_radius
	#   end_radius
	#   duration (in milliseconds)
	wedge_animator = (data)->
		do (data)->
			(frame)->
				radius = data.start_radius + ((data.end_radius - data.start_radius) * ((if frame.time < data.duration then frame.time else data.duration)) / data.duration)
				data.wedge.setRadius radius
				@stop() if frame.time > data.duration
	
		
	# set up a callback when the canvas template is rendered to keep pie chart up-to-date	
	Template.canvas.rendered = ->
		alert "not reimplemented"
		return
		update_results_graph poll_options_collection.find()			
			
		# when poll_options change, update the pie chart
		poll_options_collection.find().observe
			changed: ->
				update_results_graph poll_options_collection.find()
				

