* Animation scripts: commands with number of frames it takes / other info

cubism_animation_script1:
cubism_animation_script2:
cubism_animation_script3:
cubism_animation_script4:
cubism_animation_script5:
cubism_animation_script6:
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* 63 frames of moving out (into screen)
													dc.w	CUBISM_ANIM_STAY, 			100
													dc.w	CUBISM_ANIM_MOVEOUT_R, 	64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_SWITCH, 1					* SWITCH switch routine and start next step
													dc.w	CUBISM_ANIM_MOVEIN_R, 		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			100
													dc.w	CUBISM_ANIM_MOVEOUT, 	64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_SWITCH, 3					* SWITCH switch routine and start next step
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			512				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_MOVEOUT, 	64

													dc.w	CUBISM_ANIM_SWITCH, 1
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			128				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_MOVEOUT, 	64
													dc.w	CUBISM_ANIM_SWITCH, 3
													dc.w	CUBISM_ANIM_MOVEIN,		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_MOVEOUT, 	64
													dc.w	CUBISM_ANIM_SWITCH, 2

													dc.w	CUBISM_ANIM_RESTART,0					* restart pointer and start next anim step
*cubism_animation_script2
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* 63 frames of moving out (into screen)
													dc.w	CUBISM_ANIM_STAY, 			100
													dc.w	CUBISM_ANIM_MOVEOUT_R, 	64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_SWITCH, 1					* SWITCH switch routine and start next step
													dc.w	CUBISM_ANIM_MOVEIN_R, 		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			100
													dc.w	CUBISM_ANIM_MOVEOUT, 	64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_SWITCH, 3					* SWITCH switch routine and start next step
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			128				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_MOVEOUT, 	64
													dc.w	CUBISM_ANIM_SWITCH,5
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			384				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_MOVEOUT, 	64

													dc.w	CUBISM_ANIM_SWITCH,4
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* 63 frames of moving out (into screen)
													dc.w	CUBISM_ANIM_STAY, 			384				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_MOVEOUT, 	64
													dc.w	CUBISM_ANIM_SWITCH,5
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			250				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_MOVEOUT, 	64
													dc.w	CUBISM_ANIM_SWITCH,6
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			150				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_MOVEOUT, 	64
													dc.w	CUBISM_ANIM_SWITCH,0
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			150				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_MOVEOUT, 	64
													dc.w	CUBISM_ANIM_RESTART,2					* restart pointer and start next anim step
*cubism_animation_script3:
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* 63 frames of moving out (into screen)
													dc.w	CUBISM_ANIM_STAY, 			100
													dc.w	CUBISM_ANIM_MOVEOUT_R, 	64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_SWITCH, 1					* SWITCH switch routine and start next step
													dc.w	CUBISM_ANIM_MOVEIN_R, 		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			100
													dc.w	CUBISM_ANIM_MOVEOUT, 	64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_SWITCH, 3					* SWITCH switch routine and start next step
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			512				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_MOVEOUT, 	64

													dc.w	CUBISM_ANIM_SWITCH, 0
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_MOVEOUT, 	64
													dc.w	CUBISM_ANIM_SWITCH, 1
													dc.w	CUBISM_ANIM_MOVEIN,		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			128				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_MOVEOUT, 	64
													dc.w	CUBISM_ANIM_SWITCH, 2

													dc.w	CUBISM_ANIM_RESTART,0					* restart pointer and start next anim step

*cubism_animation_script5:
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* 63 frames of moving out (into screen)
													dc.w	CUBISM_ANIM_STAY, 			100
													dc.w	CUBISM_ANIM_MOVEOUT_R, 	64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_SWITCH, 1					* SWITCH switch routine and start next step
													dc.w	CUBISM_ANIM_MOVEIN_R, 		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			100
													dc.w	CUBISM_ANIM_MOVEOUT, 	64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_SWITCH, 3					* SWITCH switch routine and start next step
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			512				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_MOVEOUT, 	64

													dc.w	CUBISM_ANIM_SWITCH, 2
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			128				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_MOVEOUT, 	64
													dc.w	CUBISM_ANIM_SWITCH, 5
													dc.w	CUBISM_ANIM_MOVEIN,		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			128				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_MOVEOUT, 	64
													dc.w	CUBISM_ANIM_SWITCH, 6

													dc.w	CUBISM_ANIM_RESTART,0					* restart pointer and start next anim step

*cubism_animation_script4:
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* 63 frames of moving out (into screen)
													dc.w	CUBISM_ANIM_STAY, 			100
													dc.w	CUBISM_ANIM_MOVEOUT_R, 	64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_SWITCH, 1					* SWITCH switch routine and start next step
													dc.w	CUBISM_ANIM_MOVEIN_R, 		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			100
													dc.w	CUBISM_ANIM_MOVEOUT, 	64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_SWITCH, 3					* SWITCH switch routine and start next step
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			128				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_MOVEOUT, 	64
													dc.w	CUBISM_ANIM_SWITCH,5
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			384				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_MOVEOUT, 	64

													dc.w	CUBISM_ANIM_SWITCH,2
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* 63 frames of moving out (into screen)
													dc.w	CUBISM_ANIM_STAY, 			384				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_MOVEOUT, 	64
													dc.w	CUBISM_ANIM_SWITCH,3
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			250				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_MOVEOUT, 	64
													dc.w	CUBISM_ANIM_SWITCH,1
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			150				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_MOVEOUT, 	64
													dc.w	CUBISM_ANIM_SWITCH,6
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			150				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_MOVEOUT, 	64
													dc.w	CUBISM_ANIM_RESTART,0					* restart pointer and start next anim step
*cubism_animation_script6:
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* 63 frames of moving out (into screen)
													dc.w	CUBISM_ANIM_STAY, 			100
													dc.w	CUBISM_ANIM_MOVEOUT_R, 	64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_SWITCH, 1					* SWITCH switch routine and start next step
													dc.w	CUBISM_ANIM_MOVEIN_R, 		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			100
													dc.w	CUBISM_ANIM_MOVEOUT, 	64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_SWITCH, 3					* SWITCH switch routine and start next step
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			128				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_MOVEOUT, 	64
													dc.w	CUBISM_ANIM_SWITCH,1
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			384				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_MOVEOUT, 	64

													dc.w	CUBISM_ANIM_SWITCH,5
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* 63 frames of moving out (into screen)
													dc.w	CUBISM_ANIM_STAY, 			384				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_MOVEOUT, 	64
													dc.w	CUBISM_ANIM_SWITCH,7
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			250				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_MOVEOUT, 	64
													dc.w	CUBISM_ANIM_SWITCH,2
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			150				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_MOVEOUT, 	64
													dc.w	CUBISM_ANIM_SWITCH,1
													dc.w	CUBISM_ANIM_MOVEIN, 		64				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_STAY, 			150				* move out and set framecounter to X
													dc.w	CUBISM_ANIM_MOVEOUT, 	64
													dc.w	CUBISM_ANIM_RESTART,0					* restart pointer and start next anim step
