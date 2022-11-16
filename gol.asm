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
		cmpgei t1, a0, 8
		beq zero, t1, set_pixel_leds1 ; if x < 8 (and x > 3) then x is in LED[1]
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
		beq t0, zero, get_gsa_0 ; if the current gsa is 0 we do get_gsa_0, else we do get_gsa_1

		get_gsa_1:
			ldw v0, GSA1 (a0) ; we load the y line of the current gsa in v0
			ret

		get_gsa_0:
			ldw v0, GSA0 (a0) ; we load the y line of the current gsa in v0
			ret
		
	; END:get_gsa


		; BEGIN set_gsa
	set_gsa:
		ldw t0, GSA_ID (zero) ; We extract the value determining which is the current gsa 
		beq t0, zero, get_gsa_0 ; if the current gsa is 0 we do set_gsa_0, else we do set_gsa_1
		
		set_gsa_1:
			stw a0, GSA1 (a1)
			ret
	
		set_gsa_0:
			stw a0, GSA0 (a1)
			ret

	; END set_gsa

    ; BEGIN:draw_gsa
	draw_gsa:
		call clear_leds
		add t0, zero, zero
		add t1, zero, zero ;used to store value of x at given index
		addi t3, zero, 12 ;max value of x
		add a0, zero, zero
		add a1, zero, zero
		addi t5, zero, 8


		y_loop:
			add t2, zero, zero ;used to iterate over x's
			add a0, a1, t0 ;as a1 was the new a0 for a moment
			call get_gsa
			add t4, v0, zero
			
			x_loop:
				addi t0, zero, 1 ; mask used to determine value at position x
				bgeu t2, t3, y_loop

				;mask
				and t1, t0, t4
				srli t4, t4, 1 ;we shift t4 i.e. vo by one
			


				bne t1, t0, check_if_finished

				;setting_pixels
				add a1, a0, zero ;we exchange x and y for set_pixel
				add a0, t2, zero ;we add value of x to a0
				call set_pixel

			check_if_finished:
				bltu a1, t5, x_loop ;we continue while a1 < 8
			ret
	; END:draw_gsa

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
