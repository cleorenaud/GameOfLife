    ;;    game state memory location
    .equ CURR_STATE, 0x1000              ; current game state
    .equ GSA_ID, 0x1004                  ; gsa currently in use for drawing
    .equ PAUSE, 0x1008                   ; is the game paused or running
    .equ SPEED, 0x100C                   ; game speed
    .equ CURR_STEP,  0x1010              ; game current step
    .equ SEED, 0x1014                    ; game seed
    .equ GSA0, 0x1018                    ; GSA0 starting address
    .equ GSA1, 0x1038                    ; GSA1 starting address
    .equ SEVEN_SEGS, 0x1198              ; 7-segment display addresses
    .equ CUSTOM_VAR_START, 0x1200        ; Free range of addresses for custom variable definition
    .equ CUSTOM_VAR_END, 0x1300
    .equ LEDS, 0x2000                    ; LED address
    .equ RANDOM_NUM, 0x2010              ; Random number generator address
    .equ BUTTONS, 0x2030                 ; Buttons addresses

    ;; states
    .equ INIT, 0
    .equ RAND, 1
    .equ RUN, 2

    ;; constants
    .equ N_SEEDS, 4
    .equ N_GSA_LINES, 8
    .equ N_GSA_COLUMNS, 12
    .equ MAX_SPEED, 10
    .equ MIN_SPEED, 1
    .equ PAUSED, 0x00
    .equ RUNNING, 0x01

main:

	;set stack pointer at adequate value
	addi sp, zero, CUSTOM_VAR_END



;tests
	; Test update_state
	;test update state (init+b1=run)
	stw zero, CURR_STATE (zero)
	addi a0, zero, 0b00010
	call update_state

	;test update state (init+b0=init if b0<N)
	stw zero, CURR_STATE (zero)
	addi t0, zero, 2
	stw t0 , SEED (zero)
	addi a0, zero, 0b00001
	call update_state

	;test update state (init+b0=rand if b0=N)
	addi t0, zero, 3
	stw t0 , SEED (zero)
	addi a0, zero, 0b0001
	call update_state

	;test update state (run+b3=init)
	addi t0, zero, 2
	stw t0, CURR_STATE (zero)
	addi a0, zero, 0b01000
	call update_state

	;test update state (run+!b3=run)
	addi t0, zero, 2
	stw t0, CURR_STATE (zero)
	addi a0, zero, 0b00001
	call update_state

	;test update state (rand+b1=run)
	addi t0, zero, 1
	stw t0, CURR_STATE (zero)
	addi a0, zero, 0b00010
	call update_state

	;test update state (rand+!b1=rand)
	addi t0, zero, 1
	stw t0, CURR_STATE (zero)
	addi a0, zero, 0b00001
	call update_state

	;test update_state end


	;tests cell_fate
	addi a0, zero, 4
	addi a1, zero, 1
	call cell_fate
	call wait

	;tests increment_seed, should get rand mode 
	addi t0, zero, 1
	stw t0, CURR_STATE (zero)
	call increment_seed
	call draw_gsa
	call wait


	call clear_leds

	addi a0, zero, 67
	addi a1, zero, 1
	call set_gsa
	
	call draw_gsa
	call wait
	;We should get the same leds lighting up as in the 3.3.1!!!!


	;tests for random
	;call clear_leds
	;call random_gsa
	;call draw_gsa
	;call wait

	;tests for speed
	addi t0, zero, 3
	stw t0, SPEED (zero)
	call change_speed
	call change_speed
	addi a0, zero, 1
	call change_speed
	call change_speed
	ldw t0, SPEED (zero)

	;cas limites
	addi t0, zero, 10
	stw t0, SPEED (zero)
	call change_speed

	addi t0, zero, 1
	
	stw t0, SPEED (zero)
	call change_speed

	
    ; BEGIN:clear_leds
    clear_leds:
        stw zero, LEDS (zero)
		stw zero, LEDS+4 (zero)
		stw zero, LEDS+8 (zero)
        ret
    ; END:clear_leds

	
	
	
	; BEGIN:set_pixel
    set_pixel:

		addi t0, zero, 1 ; we put our temporary register to 1
		cmpgei t1, a0, 4
		beq zero, t1, set_pixel_leds0 ; if x < 4 then x is in LED[0]

		addi t0, zero, 1 ; we put our temporary register to 1
		cmpgei t1, a0, 8
		beq zero, t1, set_pixel_leds1 ; if x < 8 (and x > 3) then x is in LED[1]
	
		addi t0, zero, 1 ; we put our temporary register to 1	
		cmpgei t1, a0, 12
		beq zero, t1, set_pixel_leds2 ; if x < 12 (and x > 7) then x is in LED[3] 

		ret ; if x is bigger than 11 then we do nothing

		set_pixel_leds0: ; if the pixel is in LED[0]
			; in the 3 following line we multiply x % 4 by 8
			add t7, a0, a0
			add t7, t7, t7
			add t7, t7, t7

			add t6, a1, t7 ; the number of the pixel we want to light
			sll t0, t0, t6
			ldw t6, LEDS (zero)
			or t0, t0, t6
			stw t0, LEDS (zero) 
			ret

		set_pixel_leds1: ; if the pixel is in LED[1]
			addi t3, zero, 4
			sub t2, a0, t3 ; t2 = x - 4

			; in the 3 following line we multiply x % 4 by 8
			add t7, t2, t2
			add t7, t7, t7
			add t7, t7, t7

			add t6, a1, t7 ; the number of the pixel we want to light
			sll t0, t0, t6
			ldw t6, LEDS+4 (zero)
			or t0, t0, t6
			stw t0, LEDS+4 (zero)
			ret

		set_pixel_leds2: ; if the pixel is in LED[2]
			addi t3, zero, 8
			sub t2, a0, t3 ; t2 = x - 8

			; in the 3 following line we multiply x % 4 by 8
			add t7, t2, t2
			add t7, t7, t7
			add t7, t7, t7

			add t6, a1, t7 ; the number of the pixel we want to light
			sll t0, t0, t6
			ldw t6, LEDS+8 (zero)
			or t0, t0, t6
			stw t0, LEDS+8 (zero)
			ret
			
    ; END:set_pixel
	
	; BEGIN:wait
    wait:
		addi t0, zero, 1 ; we put our temporary register to 1
		slli t1, t0, 19; 0x80000  ;2^19
		ldw t2, SPEED(zero)

		wait_loop:
			sub t1, t1, t2 ;substract speed
			beq t1, t0, wait_exit
			br wait_loop
		wait_exit:
        	ret
    ; END:wait


	; BEGIN:get_gsa
	get_gsa:
		ldw t0, GSA_ID (zero) ; We extract the value determining which is the current gsa 
		;we will loop over a0 to be able to add +0, +4, +8... to get the correct index of the GSA
		add t1, a0, zero
		add t2, zero, zero
		add t3, zero, zero
		add t4, zero, zero
		
		a0_loop:
			add t1, t1, t2
			add t3, t3, t4
			addi t4, zero, 1
			addi t2, zero, 3 ;should it be +3 or +4 here????
			bltu t3, a0, a0_loop


		
		beq t0, zero, get_gsa_0 ; if the current gsa is 0 we do get_gsa_0, else we do get_gsa_1

		get_gsa_1:
			ldw v0, GSA1 (t1) ; we load the y line of the current gsa in v0
		ret

		get_gsa_0:
			ldw v0, GSA0 (t1) ; we load the y line of the current gsa in v0
		ret
		
	; END:get_gsa


	; BEGIN:set_gsa
	set_gsa:
		ldw t0, GSA_ID (zero) ; We extract the value determining which is the current gsa
		;we will loop over a1 to be able to add +0, +4, +8... to index the GSA correctly
		add t1, a1, zero
		add t2, zero, zero
		add t3, zero, zero
		add t4, zero, zero
		
		a1_loop:
			add t1, t1, t2
			add t3, t3, t4
			addi t4, zero, 1
			addi t2, zero, 3 ;should it be +3 or +4 here????
			bltu t3, a1, a1_loop
			
		beq t0, zero, set_gsa_0 ; if the current gsa is 0 we do set_gsa_0, else we do set_gsa_1
		
		set_gsa_1:
			stw a0, GSA1 (t1) ; we store the y line in its position in the current gsa
		ret
	
		set_gsa_0:
			stw a0, GSA0 (t1) ; we store the y line in its position in the current gsa
		ret

	; END:set_gsa

    ; BEGIN:draw_gsa
	draw_gsa:

		addi sp, sp, -4
		stw ra, 0(sp)
		call clear_leds
		ldw ra, 0(sp)
		addi sp, sp, 4

		addi s0, zero, 1 ; mask used to determine value at position x
		add s1, zero, zero ;used to store value of x at given index
		addi s3, zero, N_GSA_COLUMNS ;max value of x
		add a0, zero, zero
		add a1, zero, zero
		addi s5, zero, N_GSA_LINES


		y_loop:
			add s2, zero, zero ;used to iterate over x's

			addi sp, sp, -4
			stw ra, 0(sp)
			call get_gsa
			ldw ra, 0(sp)
			addi sp, sp, 4
			
			add s4, v0, zero
			
			x_loop:
				;mask
				and s1, s0, s4
				srli s4, s4, 1 ;we shift s4 i.e. vo by one
				bne s1, s0, check_if_finished

				;setting_pixels
				add a1, a0, zero ;we exchange x and y for set_pixel
				add a0, s2, zero ;we add value of x to a0

				addi sp, sp, -4
				stw ra, 0(sp)
				call set_pixel
				ldw ra, 0(sp)
				addi sp, sp, 4
				
				add a0, a1, zero ; we re-exchange x and y
				add a1, zero, zero ;we exchange x and y for set_pixel

			check_if_finished:
				addi s2, s2, 1
				bltu s2, s3, x_loop

				addi a0, a0, 1
				bltu a0, s5, y_loop ;we continue while a0 < 8
				
				;the value of ra is false, we are not able to ret into 0x60
				;but this command makes us ret into line : add a0, a1, zero ; we re-exchange x and y
				;why???? was ra modified by set_pixel???
				ret

			
	; END:draw_gsa


	; BEGIN:random_gsa
	random_gsa:
			add a0, zero, zero
			add a1, zero, zero
			addi s0, zero, 1 ;used to mask
			add s2, zero, zero ;used to iterate over x
			addi s3, zero, N_GSA_COLUMNS ;max value of x
			addi s5, zero, N_GSA_LINES
			
			random_y_loop:
				random_x_loop:
					ldw s1, RANDOM_NUM (zero)
					and s4, s0, s1
					or a0, a0, s4
					slli a0, a0, 1
					addi s2, s2, 1
					bltu s2, s3, random_x_loop
				srli a0, a0, 1

				addi sp, sp, -4
				stw ra, 0(sp)
				call set_gsa
				ldw ra, 0(sp)
				addi sp, sp, 4

				addi a1, a1, 1
				bltu a1, s5, random_y_loop
			ret
	; END:random_gsa





;3.5 action function

	; BEGIN:change_speed
	change_speed:
			ldw t0, SPEED (zero)
			addi t1, zero, MIN_SPEED ;min value for speed, also used as reference for #1 value
			addi t2, zero, MAX_SPEED ; max value for speed

			beq a0, t1, decrement
			increment:
				add t0, t0, t1 ;compute new value for speed
				bge t2, t0, store_speed ;10>=actual_speed we store the speed value, else we will decrement it

			decrement:
				sub t0, t0, t1 ;compute new value for speed
				blt t0, t1, increment ; if actual_speed < 1 we increment

			store_speed:
				stw t0, SPEED (zero)
			ret
	; END:change_speed

	; BEGIN:pause_game
	pause_game:
		ldw t0, PAUSE (zero)
		xori t0, t0, 1
		stw t0, PAUSE (zero)
		ret
	; END:pause_game


	; BEGIN:change_steps
	change_steps:
		ldw t0, CURR_STEP (zero)
		
		change_step_b4: ; to set the new value of the units
			beq a0, zero, change_step_b3 ; if button 4 is not pressed we don't change the value of the units
			addi t0, t0, 1 ; we add 1 to the units

		change_step_b3: ; to set the new value of the tens
			beq a1, zero, change_step_b2 ; if button 3 is not pressed we don't change the value of the tens
			addi t0, t0, 16; we add 1 to the tens	

		change_step_b2: ; to set the new value of the hundreds
			beq a2, zero, change_step_end ; if button 2 is not pressed we don't change the value of the hundreds
			addi t0, t0, 256; we add 1 to the hundreds

		change_step_end: ; once we have changed what we should, we are done
			stw t0, CURR_STEP (zero)
			ret

	; END:change_steps


	; BEGIN:increment_seed
	increment_seed:
				ldw t0, SEED (zero)
				ldw t1, CURR_STATE (zero)
				addi t2, zero, RAND

				beq t1, t2, rand_seed

				init_seed:
					addi t0, t0, 1
					stw t0, SEED (zero)

					;we update the gsa with the given seed 0,1,2 or 3
					add t3, zero, zero
					addi t4, zero, 1
					addi t5, zero, 2
					addi t6, zero, 3

					beq t0, t3, load_seed_0
					beq t0, t4, load_seed_1
					beq t0, t5, load_seed_2
					beq t0, t6, load_seed_3
					ret ; if we incremented and it is =4, we exit
	
					load_seed_0:
						;0
						add a1, zero, zero
						ldw a0, seed0 (zero)

						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

						;1
						addi a1, zero, 1
						ldw a0, seed0+4 (zero)
					
						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

						;2
						addi a1, zero, 2
						ldw a0, seed0+8 (zero)

						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

						;3
						addi a1, zero, 3
						ldw a0, seed0+12 (zero)

						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

						;4
						addi a1, zero, 4
						ldw a0, seed0+16 (zero)
						add ba, ra, zero
						call set_gsa
						add ra, ba, zero
						;5
						addi a1, zero, 5
						ldw a0, seed0+20 (zero)

						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

						;6
						addi a1, zero, 6
						ldw a0, seed0+24 (zero)

						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

						;7
						addi a1, zero, 7
						ldw a0, seed0+28 (zero)

						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

					ret

					load_seed_1:
						;0
						add a1, zero, zero
						ldw a0, seed1 (zero)

						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

						;1
						addi a1, zero, 1
						ldw a0, seed1+4 (zero)

						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

						;2
						addi a1, zero, 2
						ldw a0, seed1+8 (zero)

						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

						;3
						addi a1, zero, 3
						ldw a0, seed1+12 (zero)

						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

						;4
						addi a1, zero, 4
						ldw a0, seed1+16 (zero)

						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

						;5
						addi a1, zero, 5
						ldw a0, seed1+20 (zero)

						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

						;6
						addi a1, zero, 6
						ldw a0, seed1+24 (zero)

						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

						;7
						addi a1, zero, 7
						ldw a0, seed1+28 (zero)

						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

					ret


					load_seed_2:
						;0
						add a1, zero, zero
						ldw a0, seed2 (zero)

						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

						;1
						addi a1, zero, 1
						ldw a0, seed2+4 (zero)

						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

						;2
						addi a1, zero, 2
						ldw a0, seed2+8 (zero)

						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

						;3
						addi a1, zero, 3
						ldw a0, seed2+12 (zero)

						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

						;4
						addi a1, zero, 4
						ldw a0, seed2+16 (zero)
						add ba, ra, zero
						call set_gsa
						add ra, ba, zero
						;5
						addi a1, zero, 5
						ldw a0, seed2+20 (zero)

						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

						;6
						addi a1, zero, 6
						ldw a0, seed2+24 (zero)

						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

						;7
						addi a1, zero, 7
						ldw a0, seed2+28 (zero)

						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

					ret


					load_seed_3:
						;0
						add a1, zero, zero
						ldw a0, seed3 (zero)

						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

						;1
						addi a1, zero, 1
						ldw a0, seed3+4 (zero)

						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

						;2
						addi a1, zero, 2
						ldw a0, seed3+8 (zero)

						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

						;3
						addi a1, zero, 3
						ldw a0, seed3+12 (zero)

						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

						;4
						addi a1, zero, 4
						ldw a0, seed3+16 (zero)

						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

						;5
						addi a1, zero, 5
						ldw a0, seed3+20 (zero)

						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

						;6
						addi a1, zero, 6
						ldw a0, seed3+24 (zero)

						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

						;7
						addi a1, zero, 7
						ldw a0, seed3+28 (zero)

						addi sp, sp, -4
						stw ra, 0(sp)
						call set_gsa
						ldw ra, 0(sp)
						addi sp, sp, 4

					ret
				
				rand_seed:
					addi t0, zero, N_SEEDS
					stw t0, SEED (zero)


					addi sp, sp, -4
					stw ra, 0(sp)
					call random_gsa
					ldw ra, 0(sp)
					addi sp, sp, 4
				
				ret
	
	;END:increment_seed



   
	; BEGIN:update_state
	update_state:
		ldw t0, CURR_STATE (zero) ; t0 = current state
			
		; first we will check whether b1 = 1 (if it's the case then next state is RUN
		addi t7, zero, 1 ; we create a mask
		srli t6, a0, 1 ; the LSB of t6 is the value of b1
		and t7, t7, t6 ; if the LSB is 1 then t7 = 1 o/w t7 = 0
		beq t7, zero, update_state_chooser ; if t7 = 0 then we test other options (based on the current state)
		addi t1, zero, RUN ; if t7 = 1 then the new state is RUN
		br update_state_end

		update_state_chooser:
			addi t1, zero, INIT
			beq t0, t1, update_state_init ; we branch if current state is INIT
	
			addi t1, zero, RUN
			beq t0, t1, update_state_run ; we branch if current state is RUN
	
			addi t1, zero, RAND
			beq t0, t1, update_state_end ; all cases for when the current state is RAND are already covered

		update_state_run: ; when the current state is RUN
			addi t7, zero, 1 ; we create a mask
			srli t6, a0, 3 ; the LSB of t6 is the value of b3
			and t7, t7, t6 ; if the LSB is 1 then t7 = 1 o/w t7 = 0
			beq t7, zero, update_state_end ; if t7 = 0 then the current state won't change
			
			addi t1, zero, INIT ; if t7 = 1 then the new state is INIT
			; we push the current ra to the stack
			addi sp, sp, -4 
			stw ra, 0 (sp)
			call reset_game ; for any change of state from RUN to INIT the reset_game procedure has to be called
			; we retrieve the current ra from the stack
			ldw ra, 0 (sp)
			addi sp, sp, 4
			br update_state_end
		
		update_state_init: ; when the current state is INIT
			; first we check whether b0 is active
			addi t7, zero, 1 ; we create a mask
			and t7, t7, a0 ; if the LSB is 1 then t7 = 1 o/w t7 = 0
			beq t7, zero, update_state_end ; if t7 = 0 then the current state won't change

			; if b0 = N_SEEDS the next state is RAND o/w we do not change
			ldw t6, SEED (zero) ; t6 = N
			addi t6, t6, 1 ; as we pushed the button one more time we add one to the current seed
			cmpeqi t7, t6, N_SEEDS ; t7 = 1 if N = N_SEEDS, o/w t7 = 0
			beq t7, zero, update_state_end; if t7 = 0 we don't change the current state
		
			addi t1, zero, RAND	; if t7 = 1 then the new state is RAND
			br update_state_end

		update_state_end:
			stw t1, CURR_STATE (zero) ; we stock the new current state
			ret

	; END:update_state





		; BEGIN:select_action
	select_action:
		ldw t0, CURR_STATE (zero) ; based on the current state, each button doesn't have the same effect
		
		select_action_state_chooser:
			addi t1, zero, INIT
			beq t0, t1, select_action_init ; we branch if current state is INIT
	
			addi t1, zero, RUN
			beq t0, t1, select_action_run ; we branch if current state is RUN
	
			addi t1, zero, RAND
			beq t0, t1, select_action_rand ; we branch if current state is RAND
	
		select_action_init:
			addi t1, zero, 1 ; t1 will be a mask to check whether a button is pressed
			add s0, zero, a0 ; s0 = a0, will be used as parameters for update_state
			add t0, zero, a0 ; t0 = a0
		
			s_a_init_b0:
				and t2, t1, t0 ; t2 = 1 if b0 is pressed. t2 = 0 o/w
				beq t2, zero, s_a_init_b1 ; if b0 isn't pressed we check the other buttons
				
				; we push the current ra to the stack
				addi sp, sp, -4 
				stw ra, 0 (sp)
				call increment_seed ; if b0 is pressed we go through the predefined seeds
				call update_state
				; we retrieve the current ra from the stack
				ldw ra, 0 (sp)
				addi sp, sp, 4

				; we check if the current state changed
				addi t7, zero, RAND
				ldw t6, CURR_STATE (zero)
				bne t7, t6, s_a_init_b1 ; if the current state has not changed we check the other buttons
				
				; we push the current ra to the stack
				addi sp, sp, -4 
				stw ra, 0 (sp)
				call increment_seed ; if the current state is RAND we must re-call increment_seed
				; we retrieve the current ra from the stack
				ldw ra, 0 (sp)
				addi sp, sp, 4
				
			s_a_init_b1:
				srli t0, t0, 1 ; we shift a0, this way its LSB is b1
				; whether b1 is pressed or not, we just have to update the state

			s_a_init_b2:
				srli t0, t0, 1 ; we shift a0, this way its LSB is b2
				and t2, t1, t0 ; t2 = 1 if b2 is pressed. t2 = 0 o/w0
				addi a0, zero, 0 ; if b2 isn't pressed we set a2 to 0
				beq t2, zero, s_a_init_b3 ; if b2 isn't pressed we check the other buttons
				addi a2, zero, 1 ; if b2 is pressed we set a2 to 1

			s_a_init_b3:
				srli t0, t0, 1 ; we shift a0, this way its LSB is b3
				and t2, t1, t0 ; t2 = 1 if b3 is pressed. t2 = 0 o/w0
				addi a1, zero, 0 ; if b3 isn't pressed we set a1 to 0
				beq t2, zero, s_a_init_b4 ; if b3 isn't pressed we check the other buttons
				addi a1, zero, 1; if b3 is pressed we set a1 to 1

			s_a_init_b4:
				srli t0, t0, 1 ; we shift a0, this way its LSB is b4
				and t2, t1, t0 ; t2 = 1 if b4 is pressed. t2 = 0 o/w0
				addi a0, zero, 0 ; if b3 isn't pressed we set a0 to 1
				beq t2, zero, s_a_init_steps ; if b4 isn't pressed we are done
				addi a0, zero, 1 ; if b4 is pressed we set a0 to 1

			s_a_init_steps:
				; we push the current ra to the stack
				addi sp, sp, -4 
				stw ra, 0 (sp)
				call change_steps ; we call change_steps 
				; we retrieve the current ra from the stack
				ldw ra, 0 (sp)
				addi sp, sp, 4

				br select_action_end
			

		select_action_rand:
			addi t1, zero, 1 ; t1 will be a mask to check whether a button is pressed
			add t0, zero, a0 ; t0 = a0
		
			s_a_rand_b0:
				and t2, t1, t0 ; t2 = 1 if b0 is pressed. t2 = 0 o/w
				beq t2, zero, s_a_rand_b1 ; if b0 isn't pressed we check the other buttons
				; we push the current ra to the stack
				addi sp, sp, -4 
				stw ra, 0 (sp)
				call increment_seed ; if b0 is pressed we increment the seed
				; we retrieve the current ra from the stack
				ldw ra, 0 (sp)
				addi sp, sp, 4

			s_a_rand_b1:
				srli t0, t0, 1 ; we shift a0, this way its LSB is b1
				; whether b1 is pressed ot not, we just have to update the state

			s_a_rand_b2:
				srli t0, t0, 1 ; we shift a0, this way its LSB is b2
				and t2, t1, t0 ; t2 = 1 if b2 is pressed. t2 = 0 o/w0
				addi a0, zero, 0 ; if b2 isn't pressed we set a2 to 0
				beq t2, zero, s_a_rand_b3 ; if b2 isn't pressed we check the other buttons
				addi a2, zero, 1 ; if b2 is pressed we set a2 to 1

			s_a_rand_b3:
				srli t0, t0, 1 ; we shift a0, this way its LSB is b3
				and t2, t1, t0 ; t2 = 1 if b3 is pressed. t2 = 0 o/w0
				addi a1, zero, 0 ; if b3 isn't pressed we set a1 to 0
				beq t2, zero, s_a_rand_b4 ; if b3 isn't pressed we check the other buttons
				addi a1, zero, 1; if b3 is pressed we set a1 to 1

			s_a_rand_b4:
				srli t0, t0, 1 ; we shift a0, this way its LSB is b4
				and t2, t1, t0 ; t2 = 1 if b4 is pressed. t2 = 0 o/w0
				addi a0, zero, 0 ; if b3 isn't pressed we set a0 to 1
				beq t2, zero, s_a_rand_steps ; if b4 isn't pressed we are done
				addi a0, zero, 1 ; if b4 is pressed we set a0 to 1

			s_a_rand_steps:
				; we push the current ra to the stack
				addi sp, sp, -4 
				stw ra, 0 (sp)
				call change_steps ; we call change_steps 
				; we retrieve the current ra from the stack
				ldw ra, 0 (sp)
				addi sp, sp, 4
				
				br select_action_end 

		select_action_run:
			addi t1, zero, 1 ; t1 will be a mask to check whether a button is pressed
			add t0, zero, a0 ; t0 = a0
		
			s_a_run_b0:
				and t2, t1, t0 ; t2 = 1 if b0 is pressed. t2 = 0 o/w
				beq t2, zero, s_a_run_b1 ; if b0 isn't pressed we check the other buttons
				; we push the current ra to the stack
				addi sp, sp, -4 
				stw ra, 0 (sp)
				call pause_game ; if b0 is pressed we call pause_game
				; we retrieve the current ra from the stack
				ldw ra, 0 (sp)
				addi sp, sp, 4
				

			s_a_run_b1:
				srli t0, t0, 1 ; we shift a0, this way its LSB is b1
				and t2, t1, t0 ; t2 = 1 if b1 is pressed. t2 = 0 o/w0
				beq t2, zero, s_a_run_b2 ; if b1 isn't pressed we check the other buttons
				addi a0, zero, 0 ; a0 = 0 as we will increase the game speed
				; we push the current ra to the stack
				addi sp, sp, -4 
				stw ra, 0 (sp)
				call change_speed ; if b1 is pressed we increase the game speed
				; we retrieve the current ra from the stack
				ldw ra, 0 (sp)
				addi sp, sp, 4

			s_a_run_b2:
				srli t0, t0, 1 ; we shift a0, this way its LSB is b2
				and t2, t1, t0 ; t2 = 1 if b2 is pressed. t2 = 0 o/w0
				beq t2, zero, s_a_run_b3 ; if b2 isn't pressed we check the other buttons
				addi a0, zero, 1 ; a0 = 1 as we will decrease the game speed
				; we push the current ra to the stack
				addi sp, sp, -4 
				stw ra, 0 (sp)
				call change_speed ; if b2 is pressed we decrease the game speed
				; we retrieve the current ra from the stack
				ldw ra, 0 (sp)
				addi sp, sp, 4

			s_a_run_b3:
				srli t0, t0, 1 ; we shift a0, this way its LSB is b3
				and t2, t1, t0 ; t2 = 1 if b3 is pressed. t2 = 0 o/w0
				beq t2, zero, s_a_run_b4 ; if b3 isn't pressed we check the other buttons
				; we push the current ra to the stack
				addi sp, sp, -4 
				stw ra, 0 (sp)
				call reset_game ; if b3 is pressed we reset the game
				; we retrieve the current ra from the stack
				ldw ra, 0 (sp)
				addi sp, sp, 4

			s_a_run_b4:
				srli t0, t0, 1 ; we shift a0, this way its LSB is b4
				and t2, t1, t0 ; t2 = 1 if b4 is pressed. t2 = 0 o/w0
				beq t2, zero, select_action_end ; if b4 isn't pressed we are done
				; if b4 is pressed we remplace the current game with a new random one
				
				; TO DO

		select_action_end:
			; we push the current ra to the stack
			addi sp, sp, -4 
			stw ra, 0 (sp)
			add a0, zero, s0
			call update_state ; we also call update state
			; we retrieve the current ra from the stack
			ldw ra, 0 (sp)
			addi sp, sp, 4
			
			ret
	
	; END:select_action



	; BEGIN:cell_fate
	cell_fate:
		addi t0, zero, 1 ;check if cell is alive
		addi t1, zero, 3 ;three neighbors
		addi t2, zero, 2 ;two neighbors

		beq t0, a1, is_alive
		is_dead:
			;reproduction
			beq t1, a0, reproduce
			;nope, will be dead
			add v0, zero, zero
			ret
			reproduce:
				addi v0, zero, 1
				ret

		is_alive:
			bltu a0, t2, is_dead ;neighbors < 2 -> dieeeee
			bltu t1, a0, is_dead ; 3 < neighbors ----> dieeeee
			addi v0, zero, 1 ;else lives
			ret
	; END:cell_fate




	; 3.7. Inputs to the game

	; BEGIN:get_input
	get_input:
		ldw t0, BUTTONS+4 (zero) ; we load the falling edge detection
		addi v0, zero, t0 ; we return the value of the edgecapture register
		stw zero, BUTTONS+4 (zero) ; we clear the edgecapture register

		ret ; once it's done we can return

	; END:get_input




	; 3.8. Game step handling
	
	; BEGIN:decrement_step
	decrement_step:
		ldw t0, CURR_STATE (zero) ; we load the current state
		addi t1, zero, RUN ; t1 = 2 (RUN state)

		bne t0, t1, decrement_step_display ; if the current state is not RUN we branch

		ldw t0, CURR_STEP (zero) ; we load the current step
	
		beq t0, zero, decrement_step_zero ; if the current step is zero we branch

		addi t0, t0, -1 ; if the current step is not zero we decrement the number of steps
		stw t0, CURR_STEP (zero) ; then we store the new value
	
		br decrement_step_display ; now we will update the 7-SEG display

		decrement_step_end:
			ret ; once we are done we can return

		decrement_step_zero:
			addi v0, zero, 1 ; if the current step is zero we return one
			br decrement_step_end

		decrement_step_display:
			; we display the new number of steps on the 7-SEG display
			addi t1, zero, 1 ; we create a mask

			and t2, t0, t1 ; we extract the value of the units
			ldw t3, font_data (t2) ; we load the value corresponding to the units
			stw t3, SEVEN_SEGS (zero) ; we store the value for the SEG[3]

			srli t0, t0, 1 ; we shift t0 so its LSB is the tens
			and t2, t0, t1 ; we extract the value of the tens
			ldw t3, font_data (t2) ; we load the value corresponding to the tens
			stw t3, SEVEN_SEGS+4 (zero) ; we store the value for the SEG[2]

			srli t0, t0, 1 ; we shift t0 so its LSB is the hundreds
			and t2, t0, t1 ; we extract the value of the hundreds
			ldw t3, font_data (t2) ; we load the value corresponding to the hundreds
			stw t3, SEVEN_SEGS+8 (zero) ; we store the value for the SEG[1]

			ldw t3, font_data (zero) ; we load the value corresponding to zero
			stw t3, SEVEN_SEGS+12 (zero) ; SEG[0] is always zero

			addi v0, zero, 0 ; if the current step isn't zero we return zero
			br decrement_step_end
		
	; END:decrement_step




	; 3.9. Reset

	; BEGIN:reset_game
	reset_game:
		addi t0, zero, 1 ; t0 = 1
		stw t0, CURR_STEP (zero) ; we set the current step to 1

		stw zero, SEED (zero) ; we select the seed 0

		; the game state 0 is initialized to the seed 0

		stw zero, GSA_ID (zero) ; GSA ID is 0

		addi t0, zero, PAUSED ; t0 = 0
		stw t0, PAUSE (zero) ;  we set the game to paused

		addi t0, zero, MIN_SPEED ; t0 = 1
		stw t0, SPEED (zero) ; we set the game speed to 1 (MIN_SPEED)
		
		ret ; once we are done we return
	; END:reset_game




font_data:
    .word 0xFC ; 0
    .word 0x60 ; 1
    .word 0xDA ; 2
    .word 0xF2 ; 3
    .word 0x66 ; 4
    .word 0xB6 ; 5
    .word 0xBE ; 6
    .word 0xE0 ; 7
    .word 0xFE ; 8
    .word 0xF6 ; 9
    .word 0xEE ; A
    .word 0x3E ; B
    .word 0x9C ; C
    .word 0x7A ; D
    .word 0x9E ; E
    .word 0x8E ; F

seed0:
    .word 0xC00
    .word 0xC00
    .word 0x000
    .word 0x060
    .word 0x0A0
    .word 0x0C6
    .word 0x006
    .word 0x000

seed1:
    .word 0x000
    .word 0x000
    .word 0x05C
    .word 0x040
    .word 0x240
    .word 0x200
    .word 0x20E
    .word 0x000

seed2:
    .word 0x000
    .word 0x010
    .word 0x020
    .word 0x038
    .word 0x000
    .word 0x000
    .word 0x000
    .word 0x000

seed3:
    .word 0x000
    .word 0x000
    .word 0x090
    .word 0x008
    .word 0x088
    .word 0x078
    .word 0x000
    .word 0x000

    ;; Predefined seeds
SEEDS:
    .word seed0
    .word seed1
    .word seed2
    .word seed3

mask0:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF

mask1:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0x1FF
	.word 0x1FF
	.word 0x1FF

mask2:
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF

mask3:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0x000

mask4:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0x000

MASKS:
    .word mask0
    .word mask1
    .word mask2
    .word mask3
    .word mask4
