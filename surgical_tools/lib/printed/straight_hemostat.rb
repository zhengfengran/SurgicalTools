class StraightHemostat < CrystalScad::Printed
	def initialize(args={})
		@holding_pins_width = 7
		@holding_pins_length = 10
		# Valleys of the holding pins			
		@holding_pins_base_height = 2.2 
		# Highest part of the holding pins
		@holding_pins_height = 3.2

		# Number of pins 
		@holding_pin_count = 4	
		# Length of each pin		 
		@holding_pin_length = 1.5
		# Spacing between each pin (must be greater than pin length)
		@holding_pin_spacing = 1.5
	
		# Rotation of the holding pins
		@holding_pin_rotation = 6
		# Height of the arms and the rest apart from the hinge
		@height = 7	
		# Thickness of the arms
		@arm_thickness = 10

		# Bending radius of the arm 	
		@arm_radius=155
		@arm_angle=24
		# Additional length of straight line towards the grip
		@arm_additional_length = 25

		# spacing between the arms
		@arm_spacing = 5.2

		@hinge_area_height = @height / 2.0

		@hinge_area_diameter = 20.5
		@hinge_hole_diameter = 3.4
		@hinge_clearance = 1.5 # extra clearance for the hinge, higher values mean more possible rotation

		# TODO: The values here are guesstimated for a proof of concept model 
		@toolhead_width = 5	
		@toolhead_tip_width = 3
		@toolhead_length = 40
		
		# Angle of the two parts to each other, only for show
		@opening_angle = 0

		
		# Layer height, needed for support
		@layer_height = 0.2

		# switch used for tools that require support material 
		@add_support_for_lower = false
		@skip_hinge_hole = false

		@locking_pin_rotations = [0,-3,-7]
		@extra_valley_spacings = [0,1,1]

		@raise_upper = 0

	end
	
	def view1
		@opening_angle = 15
	end

	def view2
		@opening_angle = -4.7
		@raise_upper = 1.2
	end

	def view3
		@opening_angle = -8.3
		@raise_upper = 1.2
	end

	def view4
		@opening_angle = -11.92
		@raise_upper = 1.2
	end

	def part(show)
		@lower = nil
		@upper = nil

		# Hinge part
		@lower += cylinder(d:@hinge_area_diameter,h:@hinge_area_height)
		@upper += cylinder(d:@hinge_area_diameter,h:@hinge_area_height).translate(z:@height-@hinge_area_height)

		# Toolhead part		
		@lower += toolhead(show:show).mirror(y:1)
		@upper += toolhead(raise_z:@height-@hinge_area_height,offset:0.5,show:show).mirror(y:1)
		
		# This defines the arm shape
		pipe = RectanglePipe.new(size:[@height,@arm_thickness])

		# And an additional line, if configured 
		pipe.line(@arm_additional_length)	if @arm_additional_length > 0
		# The bent towards the hinge
		pipe.ccw(@arm_radius,@arm_angle)	
		
		@lower += pipe.pipe.mirror(x:1).translate(y:@arm_spacing,z:@height/2.0)
		# note that ruby does alter the value in pipe.pipe with the upper command, so no need to do it again
		@upper += pipe.pipe		


		if @skip_hinge_hole == false
			# Hinge inner cut
			bolt = Bolt.new(3,8,type:7380)		
			@lower -= bolt.output
			@upper -= bolt.output
		
			# nut on the other side of the hinge
			nut = Nut.new(3)
			@upper -= nut.output.translate(z:@height-1.5)
			# Support structure
			@upper += nut.add_support(@layer_height).mirror(z:1).translate(z:@height)
		end		
	

		# Cutting out the excess walls of the hinge, so it can open freely, to a degree.
		@lower -= cylinder(d:@hinge_area_diameter+@hinge_clearance,h:@hinge_area_height+0.1).translate(z:@hinge_area_height)
		@upper -= cylinder(d:@hinge_area_diameter+@hinge_clearance,h:@hinge_area_height+0.1)#.translate(z:@hinge_area_height)


		# in order to attach the grip properly, temporarily  move the arm
		@lower.translate(x:pipe.x+@arm_additional_length)
		@upper.translate(x:pipe.x+@arm_additional_length)

		# I need to calculate one side of the y value for putting the grip in the right place
		y = ((pipe.x+@arm_additional_length) / Math::sin(radians(90-@arm_angle))) * Math::sin(radians(@arm_angle)) 

		attach_grip(show,y)
	
		# Locking pins
		@lower += lower_locking_pins.translate(x:-@holding_pins_width).mirror(y:1).rotate(z:-@holding_pin_rotation).translate(y:y/2.0)
		@upper += locking_pins.mirror(z:1).translate(x:-@holding_pins_width,z:@height).mirror(y:1).rotate(z:-@holding_pin_rotation).translate(y:y/2.0)		


		if show == false && @add_support_for_lower == true
			@lower += cube([12,8,@holding_pins_height]).translate(x:-@holding_pins_width,y:3).mirror(y:1).rotate(z:-@holding_pin_rotation).translate(y:y/2.0,z:@height-@holding_pins_height)
			# fixing first tooth
			@lower += cube([12,2,@holding_pins_height+0.2]).translate(x:-@holding_pins_width,y:10).mirror(y:1).rotate(z:-@holding_pin_rotation).translate(y:y/2.0,z:@height-@holding_pins_height-0.2)

		end


		# Moving it all back to hinge as center
		@lower = @lower.translate(x:-pipe.x-@arm_additional_length)
		@upper = @upper.translate(x:-pipe.x-@arm_additional_length)

		pre_plating_mods
			
		if @raise_upper > 0
			@upper = @upper.translate(z:@raise_upper)		
		end

		if show
			res	= @lower.color("Aquamarine") 
			res += @upper.mirror(y:1).color("DarkTurquoise").rotate(z:@opening_angle)
		else
			res	= print_plate
		end	

		res		
	end

	def attach_grip(show,y)
		@lower += Grip.new(height:@height).part(show).mirror(y:1).rotate(z:-@arm_angle).translate(y:y/2.0)
		@upper += Grip.new(height:@height).part(show).mirror(y:1).rotate(z:-@arm_angle).translate(y:y/2.0)
		return nil
	end

	def pre_plating_mods	
	end

	def print_plate
		res	= @lower
		res += @upper.translate(y:@holding_pins_length*2).mirror(z:1).translate(x:16,y:12,z:@height)
		res
	end

	def locking_pins
		res = HoldingPins.new(height:@height,skip:[true,true,false],first_tooth_extra_valley_spacing:2.4).output
	end

	def lower_locking_pins
		res = HoldingPins.new(height:@height,rotations:@locking_pin_rotations,extra_valley_spacings:@extra_valley_spacings).output
	end

	def toolhead(args={})
		raise_z = args[:raise_z] || 0 # for hinge

		offset = args[:offset] || 0 # offset for better gripping

		# Hinge to toolhead connection
		res = hull(
					cylinder(d:@hinge_area_diameter,h:@hinge_area_height).translate(z:raise_z),
					cube([0.1,0.1,@hinge_area_height]).translate(z:raise_z),
					cube([0.1,0.1,@hinge_area_height]).translate(y:@toolhead_width,z:raise_z)
		)
	
		res += hull(
						cube([0.1,0.1,@height]),
						cube([0.1,0.1,@height]).translate(x:@toolhead_length),
						cube([0.1,0.1,@height]).translate(x:@toolhead_length,y:@toolhead_tip_width),
						cube([0.1,0.1,@height]).translate(y:@toolhead_width)
			)

		# The teeth are currently quite unparametric. Let's try if it works.
		(@toolhead_length/1).round.times do |i|
			res -= cylinder(d:0.8,h:@height).translate(x:(@hinge_area_diameter+@hinge_clearance)/2.0+1.2+i+offset)
		end

		# I'm removing a tiny bit more of material to not not interfere with the gripping mechanism before the "teeth" can engage
		res -= long_slot(d:1,l:1,h:@height).translate(x:(@hinge_area_diameter+@hinge_clearance)/2.0-0.5)

		res

	end

end
