
class @PieChart
	constructor: (@container)->
		# stores colors that have been used so new colors aren't too close
		@colors = []
		
		# ideally how far apart do we want the colors of the slices
		@minimum_delta_e = 30
		
		# how many times to try to pick a random color to see if it's distinct from previously used colors
		@max_attempts = 100
		
	# This is the bogosort of color solectors, but it has a limit and tries to pick a "decent" 
	#   color if it can't find a desireable one
	# getting distinct colors is actually a fairly complex thing, simple euclidian distance isn't good enough.
	#   There's a bunch of good links here: http://stackoverflow.com/questions/13586999/color-difference-similarity-between-two-values-with-js
	get_distinct_color: ->
		
		attempts = 0
		
		# store a decent color just in case - not too close to neighbor
		worst_case_color = false
		
		loop
			rgb = @get_random_color()
			
			# if we've tried and failed too many times or there are no previous colors (which means this color is always good)
			#   return a color now. 
			if ++attempts > @max_attempts or @colors.length == 0
				# console.log "FAILED to find a distinct color but WCC: #{worst_case_color}" unless @colors.length == 0
				rgb = worst_case_color or rgb
				@colors.push rgb
				return "rgb(#{rgb[0]},#{rgb[1]},#{rgb[2]})"
		
			found_another_color_too_close = false
			for color in @colors 
				# have to make it easier as more colors are added or they will all fail the test for higher delta-e's
				if (de = @delta_e.getDeltaE00FromRGB(rgb, color)) < @minimum_delta_e - @colors.length / 2
					found_another_color_too_close = true
					worst_case_color = rgb if @delta_e.getDeltaE00FromRGB(rgb, @colors[-1..][0]) > @minimum_delta_e
					break
		
			unless found_another_color_too_close
				@colors.push rgb
				return "rgb(#{rgb[0]},#{rgb[1]},#{rgb[2]})"			

		
	# update pie chart with contents of cursor parameter
	# results muts be an array of objects with attributes: "name" and "value"
	update_results_graph: (results)->
		stage = new Kinetic.Stage
			container: @container
			height: 300
			width: 300

		layer = new Kinetic.Layer()
		
		#cursor.fetch().map((option)->option.votes)
		value_total = results.map((result)->result.value).reduce (t, s)-> t + s
		
		previous_value_sum = 0
		
		# this should all be parameterized to make this more useful
		center_x = 105
		center_y = 105
		radius_base = 70
		radius_hover = 100
		text_base = 10
		text_hover = 30

		counter = 0
		# skip options with no votes so it doesn't draw radius lines for them
		wedges = []
		texts = []
		for result in results when result.value != 0				
			counter++
			value = result.value
			console.log result
			# if value == 0 then continue
			
			start_percent = previous_value_sum / value_total
			finish_percent = (previous_value_sum + value) / value_total

			start_radians = start_percent * 2 * Math.PI
			end_radians = finish_percent * 2 * Math.PI
			
			degrees = value / value_total * 360
			rotation = previous_value_sum / value_total * 360

			wedge = new Kinetic.Wedge
		        x: stage.width() / 2
		        y: stage.height() / 2
		        radius: radius_base
		        angle: degrees
		        fill: @get_distinct_color()
		        stroke: 'black'
		        strokeWidth: 4
		        rotation: rotation
			console.log wedge
			wedges.push wedge
			
			
			
			text = new Kinetic.Text
				x: stage.width() / 2 + (Math.cos((start_radians + end_radians ) / 2 ) * radius_base / 2)
				y: stage.height() / 2 +  (Math.sin((start_radians + end_radians ) / 2 ) * radius_base / 2)
				text: result.name
				fontSize: 10
				fontFamily: 'Calibri'
				fill: 'black'
				# stroke: 'black'
				# strokeWidth: 2
				
			# don't let the text interfere with the mouseover on the wedges
			text.setListening false

			# center the text
			text.offsetX text.width() / 2
			text.offsetY text.height() / 2
			console.log text
			texts.push text
	        #
	        # var simpleText = new Kinetic.Text({
	        #   x: stage.width() / 2,
	        #   y: 15,
	        #   text: 'Simple Text',
	        #   fontSize: 30,
	        #   fontFamily: 'Calibri',
	        #   fill: 'green'
	        # });

			do(wedge, text)=>
				
				# console.log "inside do wedge, this:"
				# console.log this
				wedge.on 'mouseenter', =>
						# console.log "Wedge animator function: "
						# console.log @wedge_animator
						# console.log this
						wedge.animation?.stop() # stop the previous animation if it exists
						# console.log "creating animation with wedge: "
						# console.log wedge
						# console.log "and this:"
						# console.log this
						wedge.animation = new Kinetic.Animation(@wedge_animator({wedge: wedge, text: text, text_start_size: text.getFontSize(), text_end_size: text_hover, start_radius: wedge.getRadius(), end_radius: radius_hover, duration: 250}), layer)
						wedge.animation.start()


				wedge.on 'mouseleave', =>
						wedge.animation?.stop() # stop the previous animation if it exists
						# wedge.animation = new Kinetic.Animation(@wedge_animator({wedge: wedge start_radius: wedge.getRadius(), end_radius: radius, text: text: text, text_start_size: text.getFontSize(), text_end_size: 30, duration: 250}), layer)
						wedge.animation = new Kinetic.Animation(@wedge_animator({wedge: wedge, text: text, text_start_size: text.getFontSize(), text_end_size: text_base, start_radius: wedge.getRadius(), end_radius: radius_base, duration: 250}), layer)
						
						wedge.animation.start()	
		

			

			previous_value_sum += value

		layer.add wedge for wedge in wedges
		layer.add text for text in texts
		stage.add layer
	
	
	
# takes parameters:
#   wedge
#   start_radius
#   end_radius
#   duration (in milliseconds)
PieChart::wedge_animator = (data)=>
	(frame)->
		# console.log "***Wedge generated function wedge: "
		# console.log data.wedge
		time = if frame.time < data.duration then frame.time else data.duration
		percent_complete = time / data.duration
		radius = data.start_radius + (data.end_radius - data.start_radius) * percent_complete
		data.wedge.setRadius radius
		data.text.setFontSize data.text_start_size + ((data.text_end_size - data.text_start_size) * percent_complete)
		data.text.setX 
		data.text.setOffsetX data.text.width() / 2
		data.text.setOffsetY data.text.height() / 2

		# make sure the text is visible if we're expanding
		data.text.moveToTop() if data.text_end_size > data.text_start_size

		@stop() if frame.time > data.duration
		
	
	
PieChart::get_random_color = ->
	red = Math.floor(Math.random() * 256);
	green = Math.floor(Math.random() * 256);
	blue = Math.floor(Math.random() * 256);
	
	# check colors to see if we're not too close
	# color = "rgb(#{red}#,#{green},#{blue})"
	# console.log color
	# color
	[red, green, blue]
	
PieChart::delta_e = new DeltaE()
	

