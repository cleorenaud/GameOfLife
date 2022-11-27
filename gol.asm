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
; algorithm to run the game of life
game_of_life:
	;set stack pointer at adequate value
	addi sp, zero, CUSTOM_VAR_END

	call reset_game 
	call get_input
	add s0, v0, zero ; we stock the return value of get_input in s0
	add s1, zero, zero

	game_of_life_loop:
		bne s1, zero, game_of_life ; if done != 0 we exit the loop

		add a0, s0, zero ; we push the input value of select_action
		call select_action 

		add a0, s0, zero ; we push the input value of update_state
		call update_state

		call update_gsa
		call mask
		call draw_gsa
		call wait

		call decrement_step
		add s1, zero, v0 ; we stock the return value of decrement_step in s1

		call get_input
		add s0, zero, v0
		
		br game_of_life_loop



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
			addi t2, zero, 3 
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
			addi t2, zero, 3 
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
		;making sure s's remain unchanged
		addi sp, sp, -4
		stw s0, 0(sp)
		addi sp, sp, -4
		stw s1, 0(sp)
		addi sp, sp, -4
		stw s2, 0(sp)
		addi sp, sp, -4
		stw s3, 0(sp)
		addi sp, sp, -4
		stw s4, 0(sp)
		addi sp, sp, -4
		stw s5, 0(sp)
		addi sp, sp, -4
		stw s6, 0(sp)
		addi sp, sp, -4
		stw s7, 0(sp)
		;making sure s's remain unchanged

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

		;making sure s's remain unchanged
		ldw s7, 0(sp)
		addi sp, sp, 4
		ldw s6, 0(sp)
		addi sp, sp, 4
		ldw s5, 0(sp)
		addi sp, sp, 4
		ldw s4, 0(sp)
		addi sp, sp, 4
		ldw s3, 0(sp)
		addi sp, sp, 4
		ldw s2, 0(sp)
		addi sp, sp, 4
		ldw s1, 0(sp)
		addi sp, sp, 4
		ldw s0, 0(sp)
		addi sp, sp, 4
		;making sure s's remain unchanged
		
		ret
			
	; END:draw_gsa




	; BEGIN:random_gsa
	random_gsa:
		;making sure s's remain unchanged
		addi sp, sp, -4
		stw s0, 0(sp)
		addi sp, sp, -4
		stw s1, 0(sp)
		addi sp, sp, -4
		stw s2, 0(sp)
		addi sp, sp, -4
		stw s3, 0(sp)
		addi sp, sp, -4
		stw s4, 0(sp)
		addi sp, sp, -4
		stw s5, 0(sp)
		addi sp, sp, -4
		stw s6, 0(sp)
		addi sp, sp, -4
		stw s7, 0(sp)
		;making sure s's remain unchanged

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

		;making sure s's remain unchanged
		ldw s7, 0(sp)
		addi sp, sp, 4
		ldw s6, 0(sp)
		addi sp, sp, 4
		ldw s5, 0(sp)
		addi sp, sp, 4
		ldw s4, 0(sp)
		addi sp, sp, 4
		ldw s3, 0(sp)
		addi sp, sp, 4
		ldw s2, 0(sp)
		addi sp, sp, 4
		ldw s1, 0(sp)
		addi sp, sp, 4
		ldw s0, 0(sp)
		addi sp, sp, 4
		;making sure s's remain unchanged

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
		xori t0, t0, 1 ; we change the pause state of the game
		stw t0, PAUSE (zero)
		ret
	; END:pause_game




	; BEGIN:change_steps
	change_steps:
		ldw t0, CURR_STEP (zero)
		
		change_step_b4: ; to set the new value of the units
			beq a0, zero, change_step_b3 ; if button 4 is not pressed we don't change the value of the units
			addi t0, t0, 0x001 ; we add 1 to the units

		change_step_b3: ; to set the new value of the tens
			beq a1, zero, change_step_b2 ; if button 3 is not pressed we don't change the value of the tens
			addi t0, t0, 0x010; we add 1 to the tens	

		change_step_b2: ; to set the new value of the hundreds
			beq a2, zero, change_step_end ; if button 2 is not pressed we don't change the value of the hundreds
			addi t0, t0, 0x100; we add 1 to the hundreds

		change_step_end: ; once we have changed what we should, we are done
			stw t0, CURR_STEP (zero)
			ret

	; END:change_steps




	; BEGIN:increment_seed
	increment_seed:
		;making sure s's remain unchanged
		addi sp, sp, -4
		stw s0, 0(sp)
		addi sp, sp, -4
		stw s1, 0(sp)
		addi sp, sp, -4
		stw s2, 0(sp)
		addi sp, sp, -4
		stw s3, 0(sp)
		addi sp, sp, -4
		stw s4, 0(sp)
		addi sp, sp, -4
		stw s5, 0(sp)
		addi sp, sp, -4
		stw s6, 0(sp)
		addi sp, sp, -4
		stw s7, 0(sp)
		;making sure s's remain unchanged

		ldw t0, SEED (zero) ; t0 is the current seed number
	
		ldw t1, CURR_STATE (zero) ; t1 is the current state 
		addi t2, zero, RAND ; t2 is the state RAND
		beq t1, t2, rand_seed ; if the current state is RAND we branch

		init_seed:
			addi t0, t0, 1 ; we increment the seed number 
			stw t0, SEED (zero) ; and we store the new seed number
			addi t1, zero, N_SEEDS ; t1 = N_SEEDS
			beq t0, t1, rand_seed ; if the N = N_SEEDS we must load a random seed

			; we determine which seed we must load
			addi t3, zero, 0 ; t3 = 0
			beq t0, t3, load_seed0 ; we branch if we must load seed0
			addi t3, t3, 1 ; t3 = 1
			beq t0, t3, load_seed1 ; we branch if we must load seed1
			addi t3, t3, 1 ; t3 = 2
			beq t0, t3, load_seed2 ; we branch if we must load seed2
			addi t3, t3, 1 ; t3 = 3
			beq t0, t3, load_seed3 ; we branch if we must load seed3

		rand_seed:
			addi t0, zero, N_SEEDS
			stw t0, SEED (zero)

			; we push the current ra to the stack
			addi sp, sp, -4
			stw ra, 0(sp)
			call random_gsa
			; we retrieve the current ra from the stack
			ldw ra, 0(sp)
			addi sp, sp, 4
				
			br increment_seed_end
	
		
		; Procedure to load the seed 0
		load_seed0:
			addi s7, zero, 8 ; s7 = 8, the number of time we will run the loop
			addi s6, zero, 0 ; s6 = 6, we will increment it by 4 at each iteration of the loop
			addi s5, zero, 0 ; s5 = 0, we will increment it at each iteration of the loop

		load_seed0_loop:
			beq s7, zero, increment_seed_end ; if s7 = 0 then we don't have to do the loop anymore
			
			ldw a0, seed0 (s6)
			; we push the current ra to the stack
			addi sp, sp, -4 
			stw ra, 0 (sp)
			call set_gsa
			; we retrieve the current ra from the stack
			ldw ra, 0 (sp)
			addi sp, sp, 4

			addi s6, s6, 4 ; s6 = s6 + 4
			addi s7, s7, -1 ; s7 = s7 - 1
			addi s5, s5, 1 ; s5 = s5 + 1
			addi a1, s5, 0 ; a1 = s5
			br load_seed0_loop ; we re-iterate
		; End of procedure to load the seed 0


		; Procedure to load the seed 1
		load_seed1:
			addi s7, zero, 8 ; s7 = 8, the number of time we will run the loop
			addi s6, zero, 0 ; s6 = 6, we will increment it by 4 at each iteration of the loop
			addi s5, zero, 0 ; s5 = 0, we will increment it at each iteration of the loop

		load_seed1_loop:
			beq s7, zero, increment_seed_end ; if s7 = 0 then we don't have to do the loop anymore
			
			ldw a0, seed1 (s6)
			; we push the current ra to the stack
			addi sp, sp, -4 
			stw ra, 0 (sp)
			call set_gsa
			; we retrieve the current ra from the stack
			ldw ra, 0 (sp)
			addi sp, sp, 4

			addi s6, s6, 4 ; s6 = s6 + 4
			addi s7, s7, -1 ; s7 = s7 - 1
			addi s5, s5, 1 ; s5 = s5 + 1
			addi a1, s5, 0 ; a1 = s5
			br load_seed1_loop ; we re-iterate
		; End of procedure to load the seed 1
	

		; Procedure to load the seed 2
		load_seed2:
			addi s7, zero, 8 ; s7 = 8, the number of time we will run the loop
			addi s6, zero, 0 ; s6 = 6, we will increment it by 4 at each iteration of the loop
			addi s5, zero, 0 ; s5 = 0, we will increment it at each iteration of the loop

		load_seed2_loop:
			beq s7, zero, increment_seed_end ; if s7 = 0 then we don't have to do the loop anymore
			
			ldw a0, seed2 (s6)
			; we push the current ra to the stack
			addi sp, sp, -4 
			stw ra, 0 (sp)
			call set_gsa
			; we retrieve the current ra from the stack
			ldw ra, 0 (sp)
			addi sp, sp, 4

			addi s6, s6, 4 ; s6 = s6 + 4
			addi s7, s7, -1 ; s7 = s7 - 1
			addi s5, s5, 1 ; s5 = s5 + 1
			addi a1, s5, 0 ; a1 = s5
			br load_seed2_loop ; we re-iterate
		; End of the procedure to load the seed 2


		; Procedure to load the seed 3
		load_seed3:
			addi s7, zero, 8 ; s7 = 8, the number of time we will run the loop
			addi s6, zero, 0 ; s6 = 6, we will increment it by 4 at each iteration of the loop
			addi s5, zero, 0 ; s5 = 0, we will increment it at each iteration of the loop

		load_seed3_loop:
			beq s7, zero, increment_seed_end ; if s7 = 0 then we don't have to do the loop anymore
			
			ldw a0, seed3 (s6)
			; we push the current ra to the stack
			addi sp, sp, -4 
			stw ra, 0 (sp)
			call set_gsa
			; we retrieve the current ra from the stack
			ldw ra, 0 (sp)
			addi sp, sp, 4

			addi s6, s6, 4 ; s6 = s6 + 4
			addi s7, s7, -1 ; s7 = s7 - 1
			addi s5, s5, 1 ; s5 = s5 + 1
			addi a1, s5, 0 ; a1 = s5
			br load_seed3_loop ; we re-iterate
		; End of the procedure to load the seed 3
	
		increment_seed_end:
			;making sure s's remain unchanged
			ldw s7, 0(sp)
			addi sp, sp, 4
			ldw s6, 0(sp)
			addi sp, sp, 4
			ldw s5, 0(sp)
			addi sp, sp, 4
			ldw s4, 0(sp)
			addi sp, sp, 4
			ldw s3, 0(sp)
			addi sp, sp, 4
			ldw s2, 0(sp)
			addi sp, sp, 4
			ldw s1, 0(sp)
			addi sp, sp, 4
			ldw s0, 0(sp)
			addi sp, sp, 4
			;making sure s's remain unchanged
		
		ret ; once we are done we can exit
			
	; END:increment_seed


   
	; BEGIN:update_state
	update_state:
		;making sure s's remain unchanged
		addi sp, sp, -8
		stw s0, 0(sp)
		stw s1, 0(sp)
		;making sure s's remain unchanged

		ldw s0, CURR_STATE (zero) ; s0 = current state
		addi s1, a0, 0 ; s1 is the edgecapture
			
		update_state_case1:
			; first we will check whether b1 is pressed and current_state != RUN
			cmpnei t0, s0, RUN ; t0 = 1 if current state isn't RUN, o/w t0 = 0
			srli t1, s1, 1 ; t1 LSB is the button 1 state
			andi t1, t1, 1 ; we only keep the LSB of t1
			and t0, t0, t1 ; t0 = 1 if b1 is pressed AND current state isn't RUN, o/w t0 = 0
			beq t0, zero, update_state_case2 ; if the condition isn't respected we branch

			; else the current state become run and we need to unpause the game
			addi t0, zero, RUN ; t0 = RUN
			stw t0, CURR_STATE (zero) ; current state become RUN
			addi t0, zero, RUNNING ; t0 = RUNNING
			stw t0, PAUSE (zero) ; the game is running

		update_state_case2:
			; now we check whether b0 is pressed and current state = INIT
			cmpeqi t0, s0, INIT ; t0 = 1 if current state is INIT, o/w t0 = 0
			andi t1, s1, 1 ; we only keep the input of b0 (which is the LSB)
			and t0, t0, t1 ; t0 = 1 if b0 is pressed AND current state is INIT, o/w t0 = 0
			ldw t2, SEED (zero) ; t2 = current seed N
			cmpeqi t2, t2, N_SEEDS ; t2 = 1 if N = N_SEEDS, o/w t2 = 0
			and t0, t0, t2 ; t0 = 1 if N = N_SEEDS AND b0 is pressed AND current state is INIT, o/w t0 = 0
			beq t0, zero, update_state_case3 ; if the condition isn't respected we branch

			; else the current state become RAND
			addi t0, zero, RAND ; t0 = RAND
			stw t0, CURR_STATE (zero) ; current state become RAND

		update_state_case3:
			; finally we check whether b3 is pressed and current state = RUN
			cmpeqi t0, s0, RUN ; t0 = 1 if current state is RUN, o/w t0 = 0
			srli t1, s1, 3 ; t1 LSB is the button 3 state
			andi t1, t1, 1 ; we only keep the LSB of t1
			and t0, t0, t1 ; t0 = 1 if b3 is pressed AND current state is RUN
			beq t0, zero, update_state_end ; if the condition isn't respected we branch
			
			; else we must reset the game
			; we push the current ra to the stack
			addi sp, sp, -4 
			stw ra, 0 (sp)
			call reset_game
			; we retrieve the current ra from the stack
			ldw ra, 0 (sp)
			addi sp, sp, 4

		update_state_end:
			;making sure s's remain unchanged
			ldw s1, 0(sp)
			ldw s0, 0(sp)
			addi sp, sp, 8
			;making sure s's remain unchanged

			ret ; once we are done we can exit the procedure

	; END:update_state





	; BEGIN:select_action
	select_action:
		;making sure s's remain unchanged
		addi sp, sp, -8
		stw s0, 0(sp)
		stw s1, 0(sp)
		;making sure s's remain unchanged

		; we push the current ra to the stack
		addi sp, sp, -4 
		stw ra, 0 (sp)

		ldw s0, CURR_STATE (zero) ; s0 = current state
		addi s1, a0, 0 ; s1 is the edge_capture
		cmpeqi t0, s0, RUN ; t0 = 1 if the current state is RUN, o/w t0 = 0 
		addi t1, zero, 1 ; t1 = 1
		beq t0, t1, select_action_run ; if current state is RUN we branch

		; else the current state is INIT or RAND (same implementation
		select_action_init_rand:
			s_a_i_r_b0:
				andi t0, s1, 1 ; the state of b0
				beq t0, zero, s_a_i_r_b1 ; if b0 isn't pressed we skip the next step
				call increment_seed ; we increment the seed

			s_a_i_r_b1:
				; we do nothing as update_state takes care of this part

			s_a_i_r_b2:
				srli t0, s1, 2 ; t0 LSB is the button 2 state
				andi t0, t0, 1 ; we only keep the LSB of t0
				beq t0, zero, s_a_i_r_b3 ; if b1 isn't pressed we skip the next step

				addi a0, zero, 0 ; parameter : b4 isn't pressed
				addi a1, zero, 0 ; parameter : b3 isn't pressed
				addi a2, zero, 1 ; parameter : b2 is pressed
				call change_steps ; we call change_steps with our parameters

			s_a_i_r_b3:
				srli t0, s1, 3 ; t0 LSB is the button 3 state
				andi t0, t0, 1 ; we only keep the LSB of t0
				beq t0, zero, s_a_i_r_b4 ; if b3 isn't pressed we skip the next step

				addi a0, zero, 0 ; parameter : b4 isn't pressed
				addi a1, zero, 1 ; parameter : b3 is pressed
				addi a2, zero, 0 ; parameter : b2 isn't pressed
				call change_steps ; we call change_steps with our parameters

			s_a_i_r_b4:
				srli t0, s1, 4 ; t0 LSB is the button 4 state
				andi t0, t0, 1 ; we only keep the LSB of t0
				beq t0, zero, s_a_i_r_end ; if b4 isn't pressed we skip the next step

				addi a0, zero, 1 ; parameter : b4 is pressed
				addi a1, zero, 0 ; parameter : b3 isn't pressed
				addi a2, zero, 0 ; parameter : b2 isn't pressed
				call change_steps ; we call change_steps with our parameters

			s_a_i_r_end:
				br select_action_end ; once we iterated on each button we branch

		select_action_run:		
			s_a_run_b0:
				andi t0, s1, 1 ; the state of b0
				beq t0, zero, s_a_run_b1 ; if b0 isn't pressed we skip the next step

				call pause_game ; we change the playing state of our game

			s_a_run_b1:
				srli t0, s1, 1 ; t0 LSB is the button 1 state
				andi t0, t0, 1 ; we only keep the LSB of t0
				beq t0, zero, s_a_run_b2 ; if b1 isn't pressed we skip the next step

				addi a0, zero, 0 ; parameter : we must increase the speed
				call change_speed ; we call change_speed we our parameter	

			s_a_run_b2:
				srli t0, s1, 2 ; t0 LSB is the button 2 state
				andi t0, t0, 1 ; we only keep the LSB of t0
				beq t0, zero, s_a_run_b3 ; if b2 isn't pressed we skip the next step

				addi a0, zero, 1 ; parameter : we must decrease the speed
				call change_speed ; we call change speed with our parameter

			s_a_run_b3:
				; we do nothing as update_state takes care of this part

			s_a_run_b4:
				srli t0, s1, 4 ; t0 LSB is the button 4 state
				andi t0, t0, 1 ; we only keep the LSB of t0
				beq t0, zero, s_a_run_end ; if b4 isn't pressed we skip the next step

				call random_gsa ; we replace the current game gsa with a random one
	
			s_a_run_end:
				br select_action_end ; once we iterated on each button we branch

		select_action_end:
			; we retrieve the current ra from the stack
			ldw ra, 0 (sp)
			addi sp, sp, 4
	
			;making sure s's remain unchanged
			ldw s1, 0(sp)
			ldw s0, 0(sp)
			addi sp, sp, 8
			;making sure s's remain unchanged

			ret ; once we are done we can exit the procedure
	
	; END:select_action




	; BEGIN:cell_fate
	cell_fate:
		addi t0, zero, 1 ;check if cell is alive
		addi t1, zero, 3 ;three neighbors
		addi t2, zero, 2 ;two neighbors

		beq t0, a1, is_alive ; if the cell is alive we branch

		is_dead:
			;reproduction
			beq t1, a0, reproduce ; if the cell has 3 neighbours we branch
			;nope, will be dead
			add v0, zero, zero ; return value : the cell is dead

			ret ; once we are done we exit the procedure

		reproduce:
			addi v0, zero, 1
			ret ; once we are done we exit the procedure

		is_alive:
			bltu a0, t2, is_dead ; neighbors < 2 -> dieeeee
			bltu t1, a0, is_dead ; 3 < neighbors ----> dieeeee
			addi v0, zero, 1 ; return value : the cell is alive
			ret ; once we are done we exit the procedure

	; END:cell_fate




; BEGIN:find_neighbours
	find_neighbours:
		;making sure s's remain unchanged
		addi sp, sp, -4
		stw s0, 0(sp)
		addi sp, sp, -4
		stw s1, 0(sp)
		addi sp, sp, -4
		stw s2, 0(sp)
		addi sp, sp, -4
		stw s3, 0(sp)
		addi sp, sp, -4
		stw s4, 0(sp)
		addi sp, sp, -4
		stw s5, 0(sp)
		addi sp, sp, -4
		stw s6, 0(sp)
		addi sp, sp, -4
		stw s7, 0(sp)
		;making sure s's remain unchanged


		add s7, zero, zero ;neighbours counter
		add s0, zero, a0 ;x coordinate
		add s1, zero, a1 ;y coordinate
		addi s5, zero, N_GSA_LINES
		addi s6, zero, N_GSA_COLUMNS

		addi sp, sp, -4
		stw ra, 0(sp)

		call above_neighbours
		call computing_neighbours
		call line_neighbours
		call computing_neighbours
		call under_neighbours
		call computing_neighbours

		ldw ra, 0(sp)
		addi sp, sp, 4

		add v0, zero, s7


		;making sure s's remain unchanged
		ldw s7, 0(sp)
		addi sp, sp, 4
		ldw s6, 0(sp)
		addi sp, sp, 4
		ldw s5, 0(sp)
		addi sp, sp, 4
		ldw s4, 0(sp)
		addi sp, sp, 4
		ldw s3, 0(sp)
		addi sp, sp, 4
		ldw s2, 0(sp)
		addi sp, sp, 4
		ldw s1, 0(sp)
		addi sp, sp, 4
		ldw s0, 0(sp)
		addi sp, sp, 4
		;making sure s's remain unchanged

		ret
		
		
		above_neighbours:
		beq s1, zero, last_line_neighbours
		addi a0, s1, -1
		jmpi get_the_above_gsa

		last_line_neighbours:
			addi a0, s5, -1

		get_the_above_gsa:
		addi sp, sp, -4
		stw ra, 0(sp)
		call get_gsa
		ldw ra, 0(sp)
		addi sp, sp, 4 ;now v0 contains the value of the line
		add s2, zero, v0
		ret

		line_neighbours:
		add a0, zero, s1

		addi sp, sp, -4
		stw ra, 0(sp)
		call get_gsa
		ldw ra, 0(sp)
		addi sp, sp, 4 ;now v0 contains the value of the line
		add s2, zero, v0
		ret

		under_neighbours:
		addi t0, zero, N_GSA_LINES
		addi t0, t0, -1
		beq s1, t0, first_line_neighbours
		addi a0, s1, 1
		jmpi get_the_under_gsa

		first_line_neighbours:
			add a0, zero, zero

		get_the_under_gsa:
		addi sp, sp, -4
		stw ra, 0(sp)
		call get_gsa
		ldw ra, 0(sp)
		addi sp, sp, 4 ;now v0 contains the value of the line
		add s2, zero, v0
		ret


		computing_neighbours:
		bne s0, zero, not_most_right
		addi t0, s6, -1
		srl s3, s2, t0
		slli s2, s2, 1
		or s2, s2, s3
		jmpi mask_minus_one ;is already in second to last position
		not_most_right:

		addi t0, s6, -1
		bne s0, t0, not_most_left
		addi t0, t0, -1
		srl s3, s2, t0
		andi t1, s2, 1
		slli t1, t1, 2
		or s2, s3, t1
		jmpi mask_minus_one
		not_most_left:
		
		addi t0, s0, -1
		shifting:
		srl s2, s2, t0 ;we make sure it is in second to last position
		;we apply masks
		mask_minus_one:
			addi t0, zero, 1
			and s4, t0, s2
			add s7, s7, s4

		mask_zero:
			addi t0, zero, 2
			beq s1, a0, state_of_cell
			;if not, we are either at y-1 or y+1
			and s4, t0, s2
			srli s4, s4, 1
			add s7, s7, s4
			jmpi mask_plus_one

			state_of_cell:
				and v1, t0, s2
				srli v1, v1, 1

		mask_plus_one:
			addi t0, zero, 4
			and s4, t0, s2
			srli s4, s4, 2
			add s7, s7, s4
		
		ret

	; END:find_neighbours







	; BEGIN:update_gsa
	update_gsa:
		;making sure s's remain unchanged
		addi sp, sp, -12
		stw s5, 0(sp)
		stw s6, 0(sp)
		stw s7, 0(sp)
		;making sure s's remain unchanged

		; we push the current ra to the stack
		addi sp, sp, -4 
		stw ra, 0 (sp)

		addi t0, zero, PAUSED
		ldw t1, PAUSE (zero) ; t1 is the current pause state
		beq t0, t1, update_gsa_end ; if the game is paused this procedure should do nothing

		addi s7, zero, N_GSA_LINES ; s7 = 8 (number of lines of the GSA)

		update_gsa_y_loop: 
			addi s7, s7, -1 ; we decrement our counter
			add a0, s7, zero ; the parameter of get_gsa
			call get_gsa ; we get the line corresponding to s7

			addi s6, zero, N_GSA_COLUMNS
			addi s5, zero, 0 ; will be used as the line for the gsa
			br update_gsa_x_loop

			update_gsa_x_loop_end:
				; we must change the current gsa id 
				ldw t0, GSA_ID (zero)
				xor t0, t0, t0 ; t0 = !t0
				stw t0, GSA_ID (zero)
				
				addi a0, s5, 0 ; parameter: the line
				addi a1, s7, 0 ; parameter: the y-coordinate 
				call set_gsa

				; and now we must revert it
				ldw t0, GSA_ID (zero)
				xor t0, t0, t0 ; t0 = !t0
				stw t0, GSA_ID (zero)
		
			beq s7, zero, update_gsa_y_loop_end ; if the counter is zero we exit the loop
			br update_gsa_y_loop ; else we countinue looping

		update_gsa_x_loop:
			addi s6, s6, -1 ; we decrement our counter
			addi a0, s6, 0 ; parameter: the x coordinate
			addi a1, s7, 0 ; parameter: the y coordinate
			call find_neighbours
			addi a0, v0, 0 ; parameter: the number of living neighbours
			addi a1, v1, 0 ; parameter: the (x, y) cell state 
			call cell_fate
			srl t0, v0, s6 ; we shift the return value 
			add s5, s6, s5 ; we add the new value 
			
			beq s6, zero, update_gsa_x_loop_end ; if the counter is 0 we exit the loop
			br update_gsa_x_loop ; else we continue looping
		
		update_gsa_y_loop_end:
			; we must change the current gsa id 
			ldw t0, GSA_ID (zero)
			xor t0, t0, t0 ; t0 = !t0
			stw t0, GSA_ID (zero)	

		update_gsa_end:
			; we retrieve the current ra from the stack
			ldw ra, 0 (sp)
			addi sp, sp, 4

			;making sure s's remain unchanged
			ldw s7, 0(sp)
			ldw s6, 0(sp)
			ldw s5, 0(sp)
			addi sp, sp, 12
			;making sure s's remain unchanged

			ret ; once we are done we return		
	
	; END:update_gsa




	; BEGIN:mask
	mask:
		;we apply corresponding mask to the gsa
		add t0, zero, zero
		addi t1, zero, 1
		addi t2, zero, 2
		addi t3, zero, 3
		addi t4, zero, 4

		addi s5, zero, N_GSA_LINES
		add s1, zero, zero ;counter

		ldw t5, SEED (zero)

		beq t5, t0, apply_mask_0
		beq t5, t1, apply_mask_1
		beq t5, t2, apply_mask_2
		beq t5, t3, apply_mask_3
		beq t5, t4, apply_mask_4

		ret
		
		apply_mask_0:
			ldw s0, MASKS (zero)
			jmpi apply_masks

		apply_mask_1:
			ldw s0, MASKS+4 (zero)
			jmpi apply_masks

		apply_mask_2:
			ldw s0, MASKS+8 (zero)
			jmpi apply_masks

		apply_mask_3:
			ldw s0, MASKS+12 (zero)
			jmpi apply_masks

		apply_mask_4:
			ldw s0, MASKS+16 (zero)
			jmpi apply_masks
		
		apply_masks:
		add a0, s1, zero

		addi sp, sp, -4
		stw ra, 0(sp)
		call get_gsa
		ldw ra, 0(sp)
		addi sp, sp, 4

		ldw t0, 0 (s0)

		and a0, t0, v0
		add a1, s1, zero
		
		addi sp, sp, -4
		stw ra, 0(sp)
		call set_gsa
		ldw ra, 0(sp)
		addi sp, sp, 4

		addi s0, s0, 4
		addi s1, s1, 1

		bltu s1, s5, apply_masks

		ret

	; END:mask




; 3.7. Inputs to the game

	; BEGIN:get_input
	get_input:
		ldw t0, BUTTONS+4 (zero) ; we load the falling edge detection 
		addi t1, zero, 1 ; we create a mask

		get_input_b0:
			and t2, t0, t1
			beq t2, zero, get_input_b1 ; if the LSB isn't active we branch
			addi v0, zero, 0b00001 ; return value : b0 is active
			br get_input_end

		get_input_b1:
			srli t0, t0, 1 ; we shift so that the LSB is b1
			and t2, t0, t1
			beq t2, zero, get_input_b2 ; if the LSB isn't active we branch
			addi v0, zero, 0b00010 ; return value : b1 is active	
			br get_input_end

		get_input_b2:
			srli t0, t0, 1 ; we shift so that the LSB is b1
			and t2, t0, t1
			beq t2, zero, get_input_b3 ; if the LSB isn't active we branch
			addi v0, zero, 0b00100 ; return value : b2 is active
			br get_input_end

		get_input_b3:
			srli t0, t0, 1 ; we shift so that the LSB is b1
			and t2, t0, t1
			beq t2, zero, get_input_b4 ; if the LSB isn't active we branch
			addi v0, zero, 0b01000 ; return value : b3 is active
			br get_input_end

		get_input_b4:
			srli t0, t0, 1 ; we shift so that the LSB is b1
			and t2, t0, t1
			beq t2, zero, get_input_no_button ; if the LSB isn't active we branch
			addi v0, zero, 0b10000 ; return value : b4 is active
			br get_input_end

		get_input_no_button:
			addi v0, zero, 0b00000 ; return value : no button is active

		get_input_end:
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
			ldw t0, CURR_STEP (zero)

			; we extract the value of the units
			slli t1, t0, 28
			srli t1, t1, 28
			; we must multiply t1 by 4
			add t1, t1, t1 
			add t1, t1, t1
			ldw t3, font_data (t1) ; we load the value corresponding to the units
			stw t3, SEVEN_SEGS+12 (zero) ; we store the value for the SEG[3]

			; we extract the value of the tens
			slli t1, t0, 24
			srli t1, t1, 28
			; we must multiply t1 by 4
			add t1, t1, t1 
			add t1, t1, t1
			ldw t3, font_data (t1) ; we load the value corresponding to the tens
			stw t3, SEVEN_SEGS+8 (zero) ; we store the value for the SEG[2]

			; we extract the value of the hundreds
			slli t1, t0, 20
			srli t1, t1, 28
			; we must multiply t1 by 4
			add t1, t1, t1 
			add t1, t1, t1
			ldw t3, font_data (t1) ; we load the value corresponding to the hundreds
			stw t3, SEVEN_SEGS+4 (zero) ; we store the value for the SEG[1]

			ldw t3, font_data (zero) ; we load the value corresponding to zero
			stw t3, SEVEN_SEGS (zero) ; SEG[0] is always zero

			addi v0, zero, 0 ; if the current step isn't zero we return zero
			br decrement_step_end
		
	; END:decrement_step




; 3.9. Reset

	
	; BEGIN:reset_game
	reset_game:
		;making sure s's remain unchanged
		addi sp, sp, -12
		stw s5, 0(sp)
		stw s6, 0(sp)
		stw s7, 0(sp)
		;making sure s's remain unchanged

		addi t0, zero, INIT
		stw t0, CURR_STATE (zero) ; we put the current state to 0

		addi t0, zero, 1 ; s0 = 1
		stw t0, CURR_STEP (zero) ; we set the current step to 1

		; now we display the current step on the display
		ldw t0, font_data (zero) ; we load the value corresponding to zero
		stw t0, SEVEN_SEGS (zero) ; SEG[0] is always zero
		stw t0, SEVEN_SEGS+4 (zero) ; SEG[1] must be zero
		stw t0, SEVEN_SEGS+8 (zero) ; SEG[2] must be zero 
		ldw t0, font_data+4 (zero) ; we load the value corresponding to one
		stw t0, SEVEN_SEGS+12 (zero) ; SEG[3] must be one

		stw zero, SEED (zero) ; we select the seed 0

		stw zero, GSA_ID (zero) ; GSA ID is 0

		; the GSA 0 is initialized to the seed 0
		; we load the seed 0 in our current GSA

		addi s7, zero, N_GSA_LINES ; s7 = 8, the number of time we will run the loop
		addi s6, zero, 0 ; s6 = 0, we will increment it by 4 at each iteration of the loop
		addi s5, zero, 0 ; s5 = 0, we will increment it at each iteration of the loop

		reset_game_seed_loop:
			beq s7, zero, reset_game_end ; if s7 = 0 then we don't have to do the loop anymore
			
			ldw a0, seed0 (s6)
			; we push the current ra to the stack
			addi sp, sp, -4 
			stw ra, 0 (sp)
			call set_gsa
			; we retrieve the current ra from the stack
			ldw ra, 0 (sp)
			addi sp, sp, 4

			addi s6, s6, 4 ; s6 = s6 + 4
			addi s7, s7, -1 ; s7 = s7 - 1
			addi s5, s5, 1 ; s5 = s5 + 1
			addi a1, s5, 0 ; a1 = s5
			br reset_game_seed_loop ; we re-iterate

		reset_game_end:

		; we push the current ra to the stack
		addi sp, sp, -4 
		stw ra, 0 (sp)
		call draw_gsa ; we display the GSA on the LED
		; we retrieve the current ra from the stack
		ldw ra, 0 (sp)
		addi sp, sp, 4

		addi t0, zero, PAUSED ; t0 = 0
		stw t0, PAUSE (zero) ;  we set the game to paused

		addi t0, zero, MIN_SPEED ; t0 = 1
		stw t0, SPEED (zero) ; we set the game speed to 1 (MIN_SPEED)

		;making sure s's remain unchanged
		ldw s7, 0(sp)
		ldw s6, 0(sp)
		ldw s5, 0(sp)
		addi sp, sp, 12
		;making sure s's remain unchanged
		
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