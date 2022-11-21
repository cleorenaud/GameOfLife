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
;tests
	call clear_leds
	addi a0, zero, 3
	addi a1, zero, 0
	call set_gsa
	addi a0, zero, 67
	addi a1, zero, 1
	call set_gsa
	addi a0, zero, 128
	addi a1, zero, 2
	call set_gsa
	addi a0, zero, 224
	addi a1, zero, 3
	call set_gsa
	addi a0, zero, 0
	addi a1, zero, 4
	call set_gsa
	addi a0, zero, 2
	addi a1, zero, 5
	call set_gsa
	addi a0, zero, 4
	addi a1, zero, 6
	call set_gsa
	addi a0, zero, 7
	addi a1, zero, 7
	call set_gsa

	call draw_gsa
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




	; BEGIN set_gsa
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

	; END set_gsa




    ; BEGIN:draw_gsa
	draw_gsa:
		call clear_leds
		addi s0, zero, 1 ; mask used to determine value at position x
		add s1, zero, zero ;used to store value of x at given index
		add a0, zero, zero
		add a1, zero, zero

		y_loop:
			add s2, zero, zero ;used to iterate over x's
			
			call get_gsa
			add s4, v0, zero
			
			x_loop:
				;mask
				and s1, s0, s4
				srli s4, s4, 1 ;we shift s4 i.e. vo by one
				bne s1, s0, check_if_finished

				;setting_pixels
				add a1, a0, zero ;we exchange x and y for set_pixel
				add a0, s2, zero ;we add value of x to a0
				call set_pixel
				add a0, a1, zero ; we re-exchange x and y
				add a1, zero, zero ;we exchange x and y for set_pixel

			check_if_finished:
				addi s2, s2, 1
				bltu s2, N_GSA_COLUMNS, x_loop

				addi a0, a0, 1
				bltu a0, N_GSA_LINES, y_loop ;we continue while a0 < 8
				
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
			
			random_y_loop:
				random_x_loop:
					ldw s1, RANDOM_NUM (zero)
					and s4, s0, s1
					or a0, a0, s4
					slli a0, a0, 1
					addi s2, s2, 1
					bltu s2, N_GSA_COLUMNS, random_x_loop
				srli a0, a0, 1
				call set_gsa
				addi a1, a1, 1
				bltu a1, N_GSA_LINES, random_y_loop
			ret ;same problem here, we ret to line addi a1, a1, 1 just above, how to store the value of ra???????
	; END:random_gsa




;3.5 action function

	; BEGIN:change_step
	change_step:
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

	; END:change_step




	; BEGIN:pause_game
	pause_game:
		ldw t0, PAUSE (zero)
		xori t0, t0, 1
		stw t0, PAUSE (zero)
		ret
	; END:pause_game




	; BEGIN:increment_seed
	increment_seed:
				ldw s0, SEED (zero)
				ldw s1, CURR_STATE (zero)

				beq s1, RAND, rand_seed

				init_seed:
					addi s0, s0, 1
					stw s0, SEED (zero)
					ret
				
				rand_seed:
					call random_gsa
					ret

				N_SEEDS????????
	
	;END:increment_seed



   

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
