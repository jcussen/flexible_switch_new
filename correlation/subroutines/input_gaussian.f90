!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!              IMPLEMENTATION OF INHOMOGENEOUS POISSON INPUT                 !!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	SUBROUTINE input_g(t)
	USE PARAMETERS
	USE VARIABLES
	USE TEMP
	IMPLICIT NONE
	INTEGER			::	pw,t,j0,jf,i,j
	REAL*8 			::	randg
!======================= generating correlations in groups of neurons =====================!
	IF(MOD(t,10).EQ.0) THEN							!update every 10 time steps - since OU time step update is 1 ms
	!---------------------------- loop over input signals -------------------------------------!
		DO pw = 1,n_pw
			CALL grand(1.0d0,randg)					!call random number from gaussian distribution
			patt_time(pw) = patt_time(pw)*pr(81) + randg		!decay of rate envelope and addition of random gaussian noise
		!----------------------- from random variable to spike probability ------------------------!
			IF(patt_time(pw).GT.0.0d0) THEN		!if positive
				inp_patt(((pw-1)*ne_pw)+1:ne_pw*pw) = (pr(83)*dt*patt_time(pw))/1000.0d0
				inp_patt(((pw-1)*ni_pw1)+ne+1:ne+ni_pw1*pw) = (pr(84)*dt*patt_time(pw))/1000.0d0
				inp_patt(((pw-1)*ni_pw2)+ne+ni1+1:ne+ni1+ni_pw2*pw) = (pr(84)*dt*patt_time(pw))/1000.0d0
			!------------------------------------------------------------------------------------------!
			ELSE					!rectification
				inp_patt(((pw-1)*ne_pw)+1:ne_pw*pw) = 0.0d0
				inp_patt(((pw-1)*ni_pw1)+ne+1:ne+ni_pw1*pw) = 0.0d0
				inp_patt(((pw-1)*ni_pw2)+ne+ni1+1:ne+ni1+ni_pw2*pw) = 0.0d0
			END IF
		!------------------------------------------------------------------------------------------!
		END DO
	!------------------------------------------------------------------------------------------!
	END IF
!==========================================================================================!
!======================== generate spikes from rate probabilities =========================!
!-------------------------- resetting presynaptic spikes variables ------------------------!
	spkr = 0.0d0
	spk = .FALSE.
!------------------------------------------------------------------------------------------!
!------------------------ vector with random numbers between 0 and 1 ----------------------!
	CALL RANDOM_NUMBER(tmp_inp)
!------------------------------------------------------------------------------------------!
!------------------------- excitatory neurons ---------------------------------------------!
	j0 = 1			!vector starting point
	jf = ne			!vector ending point
!------------ finding neurons that spiked and implementing refrac period ------------------!
	WHERE((tmp_inp(j0:jf).LE.(pr(75)+inp_patt(j0:jf))).AND.(tr-spkt(j0:jf).GT.pr(3)))
		spk(j0:jf) = .TRUE.	!spike variable to YES
		spkt(j0:jf) = tr	!spike time update
		spkr(j0:jf) = 1.0d0	!spike variable for inputs
		spkt_pre_total(j0:jf)=spkt_pre_total(j0:jf)+1 !add one to total spike count for neurons that spiked
	END WHERE
!------------------------------------------------------------------------------------------!
!------------------------------------------------------------------------------------------!
!------------------------ inhibitory neurons pop 1 ----------------------------------------!
	j0 = ne + 1		!vector starting point
	jf = ne + ni1		!vector ending point
!------------ finding neurons that spiked and implementing refrac period ------------------!
	WHERE((tmp_inp(j0:jf).LE.(pr(76)+pr(205)*inp_patt(j0:jf))).AND.(tr-spkt(j0:jf).GT.(0.5d0*pr(3))))
		spk(j0:jf) = .TRUE.	!spike variable to YES
		spkt(j0:jf) = tr	!spike time update
		spkr(j0:jf) = 1.0d0	!spike variable for inputs
		spkt_pre_total(j0:jf)=spkt_pre_total(j0:jf)+1 !add one to total spike count for neurons that spiked
	END WHERE
!------------------------------------------------------------------------------------------!
!------------------------------------------------------------------------------------------!
!------------------------- inhibitory neurons pop 2 ---------------------------------------!
	j0 = ne + ni1 + 1	!vector starting point
	jf = ne + ni1 + ni2	!vector ending point
!------------ finding neurons that spiked and implementing refrac period ------------------!
	WHERE((tmp_inp(j0:jf).LE.(pr(76)+pr(206)*inp_patt(j0:jf))).AND.(tr-spkt(j0:jf).GT.(0.5d0*pr(3))))
		spk(j0:jf) = .TRUE.	!spike variable to YES
		spkt(j0:jf) = tr	!spike time update
		spkr(j0:jf) = 1.0d0	!spike variable for inputs
		spkt_pre_total(j0:jf)=spkt_pre_total(j0:jf)+1 !add one to total spike count for neurons that spiked
	END WHERE

!------------------------------------------------------------------------------------------!
!------------------------- loop through all neurons ---------------------------------------!
	! indices = PACK([(i, i=1,size(spkt))], spkt.EQ.tr)
	
	! DO j=1, size(indices) 
	! 	IF (indices(j)<=ne) THEN
	! 		spkt_ex(spkt_pre_total(indices(j)), indices(j))=spkt(indices(j))
	! 	ELSE IF (indices(j)<=ne+ni1) THEN
   	! 		spkt_in1(spkt_pre_total(indices(j)), indices(j)-ne)=spkt(indices(j))
	! 	ELSE IF (indices(j)<=ne+ni1+ni2) THEN
	! 		spkt_in2(spkt_pre_total(indices(j)), indices(j)-ne-ni1)=spkt(indices(j))
	! 	END IF
	! END DO

	DO j=1, ne+ni1+ni2 !this works but is not very efficient
		IF (spk(j)) THEN
			IF (j<=ne) THEN
				spkt_ex(spkt_pre_total(j), j)=spkt(j)
			ELSE IF (j<=ne+ni1) THEN
				spkt_in1(spkt_pre_total(j), j-ne)=spkt(j)
			ELSE IF (j<=ne+ni1+ni2) THEN
				spkt_in2(spkt_pre_total(j), j-ne-ni1)=spkt(j)
			END IF
		END IF
	END DO



	! IF (spk(2)) THEN
	! 	spkt_pre_test(spkt_pre_total(2))=spkt(2)
	! END IF

!------------------------------------------------------------------------------------------!
!------------------------------------------------------------------------------------------!
!==========================================================================================!
!=========================== update synaptic conductances =================================!
!-------------------------excitatory neurons-----------------------------------------------!
	x(2) = x(2) + SUM(spkr(1:ne)*msynw(1:ne))
!------------------------------------------------------------------------------------------!
!-------------------------inhibitory neurons-----------------------------------------------!
	x(3) = x(3) + SUM(spkr(ne+1:ne+ni1+ni2)*msynw(ne+1:ne+ni1+ni2))
!------------------------------------------------------------------------------------------!
!==========================================================================================!
!=========================== mean firing-rate of input signals ============================!
	DO pw = 1,n_pw
		activity(pw) = activity(pw)*pr(87) + pr(88)*SUM(spkr(((pw-1)*ne_pw)+1:pw*ne_pw)) !this is only the excitatory activity firing rate?
		activity_in1(pw) = activity_in1(pw)*pr(87) + pr(88)*SUM(spkr(((pw-1)*ni_pw1)+ne+1:pw*ni_pw1+ne))
		activity_in2(pw) = activity_in2(pw)*pr(87) + pr(88)*SUM(spkr(((pw-1)*ni_pw2)+ne+ni1+1:pw*ni_pw2+ne+ni1))
	END DO
	
	
!==========================================================================================!
	END SUBROUTINE
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!             PSEUDO RANDOM GAUSSIAN RANDOM NUMBER GENERATOR                 !!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	SUBROUTINE grand(std_dev,randg)		!arguments -> standard deviation, and output
	USE PARAMETERS
	IMPLICIT NONE
	REAL*8 :: random_number_g(2),std_dev
	REAL*8 :: randg
!------------------------ ramdom number between 0 and 1 -----------------------------------!
	CALL RANDOM_NUMBER(random_number_g)
!------------------------------------------------------------------------------------------!
!------------------------- generating gaussian random number ------------------------------!
	randg = std_dev*DSQRT( -2.0d0*DLOG(random_number_g(1)) )*DCOS( dpi*random_number_g(2) )
!------------------------------------------------------------------------------------------!
	END SUBROUTINE
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
