!------------------------------------------------------------------------------
!          Harvard University Atmospheric Chemistry Modeling Group            !
!------------------------------------------------------------------------------
!BOP
!
! !MODULE: megan_mod
!
! !DESCRIPTION: Module MEGAN\_MOD contains variables and routines specifying 
!  the algorithms that control the MEGAN inventory of biogenic emissions.
!\\
!\\
!  References:
!
!  \begin{itemize}
!  \item Guenther, A., et al., \emph{A global model of natural volatile 
!        organic compound emissions}, \underline{J.Geophys. Res.}, 
!        \textbf{100}, 8873-8892, 1995.
!  \item Wang, Y., D. J. Jacob, and J. A. Logan, \emph{Global simulation of 
!        tropospheric O3-Nox-hydrocarbon chemistry: 1. Model formulation}, 
!        \underline{J. Geophys. Res.}, \textbf{103}, D9, 10713-10726, 1998.
!  \item Guenther, A., B. Baugh, G. Brasseur, J. Greenberg, P. Harley, L. 
!        Klinger, D. Serca, and L. Vierling, \emph{Isoprene emission estimates 
!        and uncertanties for the Central African EXPRESSO study domain}, 
!        \underline{J. Geophys. Res.}, \textbf{104}, 30,625-30,639, 1999.
!  \item Guenther, A. C., T. Pierce, B. Lamb, P. Harley, and R. Fall, 
!        \emph{Natural emissions of non-methane volatile organic compounds, 
!        carbon monoxide, and oxides of nitrogen from North America}, 
!        \underline{Atmos. Environ.}, \textbf{34}, 2205-2230, 2000.
!  \item Guenther, A., and C. Wiedinmyer, \emph{User's guide to Model of 
!        Emissions of Gases and Aerosols from Nature}. http://cdp.ucar.edu. 
!        (Nov. 3, 2004) 
!  \item Guenther, A., \emph{AEF for methyl butenol}, personal commucation. 
!        (Nov, 2004)
!  \end{itemize}
!
! !INTERFACE:
!
      MODULE MEGAN_MOD
!
! !USES:
!
      USE ERROR_MOD, ONLY : ERROR_STOP

      IMPLICIT NONE
      PRIVATE

#     include "CMN_SIZE"                               ! Size parameters
!
! !DEFINED PARAMETERS:
! 
      ! Scalars
#if   defined( MERRA ) 
      INTEGER, PARAMETER  :: DAY_DIM        = 24       ! # of 1-hr periods/day
#else
      INTEGER, PARAMETER  :: DAY_DIM        = 8        ! # of 3-hr periods/day
#endif
      INTEGER, PARAMETER  :: NUM_DAYS       = 10       ! # of days to avg 
      REAL*8,  PARAMETER  :: WM2_TO_UMOLM2S = 4.766d0  ! W/m2 -> umol/m2/s

      ! Some conversions factors (mpb,2009)
      REAL*8, PARAMETER   :: D2RAD =  3.14159d0 /   180.0d0  ! Deg -> Radians
      REAL*8, PARAMETER   :: RAD2D =    180.0d0 / 3.14159d0  ! Radians -> Deg
      REAL*8, PARAMETER   :: PI    =  3.14159d0              ! PI
!
! !PRIVATE TYPES:
!
      ! Past light & temperature conditions (mpb,2009)
      ! (1) Temperature at 2m (TS):
      REAL*8, ALLOCATABLE :: T_DAILY(:,:)       ! Daily averaged sfc temp
      REAL*8, ALLOCATABLE :: T_DAY(:,:,:)       ! Holds 1 day of sfc temp data
      REAL*8, ALLOCATABLE :: T_15(:,:,:)        ! Holds 15 days of daily avg T
      REAL*8, ALLOCATABLE :: T_15_AVG(:,:)      ! Sfc temp avg'd over NUM_DAYS

      ! (2) PAR Direct: 
      REAL*8, ALLOCATABLE :: PARDR_DAILY(:,:)   ! Average daily PARDR
      REAL*8, ALLOCATABLE :: PARDR_DAY(:,:,:)   ! Holds 1 day of PARDR data
      REAL*8, ALLOCATABLE :: PARDR_15(:,:,:)    ! 10 days of daily avg'd PARDR
      REAL*8, ALLOCATABLE :: PARDR_15_AVG(:,:)  ! PARDR averaged over NUM_DAYS

      ! (3) PAR Diffuse: 
      REAL*8, ALLOCATABLE :: PARDF_DAILY(:,:)   ! Average daily PARDR
      REAL*8, ALLOCATABLE :: PARDF_DAY(:,:,:)   ! Holds 1-day of PARDR data
      REAL*8, ALLOCATABLE :: PARDF_15(:,:,:)    ! 10 days of daily avg'd PARDR 
      REAL*8, ALLOCATABLE :: PARDF_15_AVG(:,:)  ! PARDF averaged over NUM_DAYS

      ! Annual emission factor arrays (mpb,2009)
      REAL*8, ALLOCATABLE :: AEF_ISOP(:,:)      ! Isoprene 
      REAL*8, ALLOCATABLE :: AEF_MONOT(:,:)     ! Total monoterpenes
      REAL*8, ALLOCATABLE :: AEF_MBO(:,:)       ! Methyl butenol
      REAL*8, ALLOCATABLE :: AEF_OVOC(:,:)      ! Other biogenic VOC's
      REAL*8, ALLOCATABLE :: AEF_APINE(:,:)     ! Alpha-pinene
      REAL*8, ALLOCATABLE :: AEF_BPINE(:,:)     ! Beta-pinene
      REAL*8, ALLOCATABLE :: AEF_LIMON(:,:)     ! Limonene
      REAL*8, ALLOCATABLE :: AEF_SABIN(:,:)     ! Sabine
      REAL*8, ALLOCATABLE :: AEF_MYRCN(:,:)     ! Myrcene
      REAL*8, ALLOCATABLE :: AEF_CAREN(:,:)     ! 3-Carene
      REAL*8, ALLOCATABLE :: AEF_OCIMN(:,:)     ! Ocimene
      ! bug fix: causes issues in parallel (hotp 3/10/10) 
      !REAL*8, ALLOCATABLE :: AEF_SPARE(:,:)     ! Temp array for monoterp's

      ! Path to MEGAN emission factors
      CHARACTER(LEN=20)   :: MEGAN_SUBDIR = 'MEGAN_200909/'
!
! !PUBLIC MEMBER FUNCTIONS: 
!
      PUBLIC  :: ACTIVITY_FACTORS
      PUBLIC  :: CLEANUP_MEGAN   
      PUBLIC  :: GET_EMISOP_MEGAN  
      PUBLIC  :: GET_EMMBO_MEGAN    
      PUBLIC  :: GET_EMMONOG_MEGAN 
      PUBLIC  :: GET_EMMONOT_MEGAN 
      PUBLIC  :: GET_AEF   
      PUBLIC  :: GET_AEF_05x0666        
      PUBLIC  :: INIT_MEGAN        
      PUBLIC  :: UPDATE_T_DAY      
      PUBLIC  :: UPDATE_T_15_AVG   
!
! !PRIVATE MEMBER FUNCTIONS:
!
      PRIVATE :: GET_GAMMA_LAI
      PRIVATE :: GET_GAMMA_LEAF_AGE
      PRIVATE :: GET_GAMMA_P
      PRIVATE :: GET_GAMMA_T_ISOP
      PRIVATE :: GET_GAMMA_T_NISOP
      PRIVATE :: GET_GAMMA_P_PECCA
      PRIVATE :: SOLAR_ANGLE
! 
! !REVISION HISTORY: 
!  (1 ) Original code (biogen_em_mod.f) by Dorian Abbot (6/2003).  Updated to 
!        latest algorithm and modified for the standard code by May Fu 
!        (11/2004).
!  (2 ) All emission are currently calculated using TS from DAO met field.
!        TS is the surface air temperature, which should be carefully 
!        distinguished from TSKIN. (tmf, 11/20/2004)
!  (3 ) In GEOS4, the TS used here are the T2M in the A3 files, read in 
!        'a3_read_mod.f'. 
!  (4 ) Bug fix: change #if block to also cover GCAP met fields (bmy, 12/6/05)
!  (5 ) Remove support for GEOS-1 and GEOS-STRAT met fields (bmy, 8/4/06)
!  (6 ) Bug fix: Skip Feb 29th if GCAP in INIT_MEGAN (phs, 9/18/07)
!  (7 ) Added routine GET_AEF_05x0666 to read hi-res AEF data for the GEOS-5
!        0.5 x 0.666 nested grid simulations (yxw, dan, bmy, 11/6/08)
!  17 Dec 2009 - R. Yantosca - Added ProTeX headers
!  09 Mar 2010 - R. Yantosca - Minor bug fix in GET_EMMONOT_MEGAN
!  17 Mar 2010 - H. Pye      - AEF_SPARE must be a scalar local variable
!                              in GET_EMMONOT_MEGAN for parallelization.
!  20 Aug 2010 - R. Yantosca - Move CMN_SIZE to top of module
!  20 Aug 2010 - R. Yantosca - Now set DAY_DIM = 24 for MERRA, since the
!                              surface temperature is now an hourly field.
!  01 Sep 2010 - R. Yantosca - Bug fix in INIT_MEGAN: now only read in 
!                              NUM_DAYS (instead of 15) days of sfc temp data 
!EOP
!------------------------------------------------------------------------------
!BOC
      CONTAINS
!EOC
!------------------------------------------------------------------------------
!          Harvard University Atmospheric Chemistry Modeling Group            !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: get_emisop_megan
!
! !DESCRIPTION: Subroutine GET\_EMISOP\_MEGAN computes isoprene emissions in 
!  units of [atoms C/box] using the MEGAN inventory.
!\\
!\\
! !INTERFACE:
!
      FUNCTION GET_EMISOP_MEGAN( I,  J,     SUNCOS, 
     &                           TS, Q_DIR, Q_DIFF, XNUMOL )
     &         RESULT( EMISOP )
!
! !USES:
!
      USE LAI_MOD,     ONLY : ISOLAI, MISOLAI, PMISOLAI, DAYS_BTW_M
      USE LOGICAL_MOD, ONLY : LPECCA 
!
! !INPUT PARAMETERS: 
!
      ! Arguments
      INTEGER, INTENT(IN) :: I, J    ! GEOS-Chem lon & lat indices
      REAL*8,  INTENT(IN) :: SUNCOS  ! Solar zenith angle [unitless]
      REAL*8,  INTENT(IN) :: TS      ! Surface temperature [K]
      REAL*8,  INTENT(IN) :: Q_DIR   ! Flux of direct PAR above canopy [W/m2]
      REAL*8,  INTENT(IN) :: Q_DIFF  ! Flux of diffuse PAR above canopy [W/m2]
      REAL*8,  INTENT(IN) :: XNUMOL  ! Number of atoms C / kg C 
!
! !RETURN VALUE:
!
      REAL*8              :: EMISOP  ! Isoprene emissions [atoms C/box]
!
! !REMARKS:
!  References (see above for full citations):
!  ============================================================================
!  (1 ) Guenther et al, 1995, 1999, 2000, 2004, 2006
!  (2 ) Wang,    et al, 1998
!  (3 ) Guenther et al, 2007, MEGAN v2.1 User mannual 
! 
! !REVISION HISTORY: 
!  (1 ) Original code by Dorian Abbot (9/2003).  Updated to the latest 
!        algorithm and modified for the standard code by May Fu (11/20/04)
!  (2 ) All MEGAN biogenic emission are currently calculated using TS from DAO 
!        met field. TS is the surface air temperature, which should be 
!        carefully distinguished from TSKIN. (tmf, 11/20/04)
!  (3 ) Restructing of function & implementation of activity factors (mpb,2009)
!  17 Dec 2009 - R. Yantosca - Added ProTeX headers
!EOP
!------------------------------------------------------------------------------
!BOC
!
! !LOCAL VARIABLES:
!
      INTEGER             :: IJLOOP
      REAL*8              :: GAMMA_LAI
      REAL*8              :: GAMMA_LEAF_AGE
      REAL*8              :: GAMMA_P
      REAL*8              :: GAMMA_P_PECCA
      REAL*8              :: GAMMA_T
      REAL*8              :: GAMMA_SM
      REAL*8              :: D_BTW_M, Q_DIR_2, Q_DIFF_2
            
      !=================================================================
      ! GET_EMISOP_MEGAN begins here!
      !================================================================= 

      ! Initialize return value & activity factors
      EMISOP          = 0.d0
      GAMMA_T         = 0.d0
      GAMMA_LAI       = 0.d0
      GAMMA_LEAF_AGE  = 0.d0
      GAMMA_P         = 0.d0
      GAMMA_SM        = 0.d0

      ! Number of days between MISOLAI and PMISOLAI
      D_BTW_M  = DBLE( DAYS_BTW_M )

      ! 1-D array index
      IJLOOP   = ( (J-1) * IIPAR ) + I
      
      ! Convert Q_DIR and Q_DIFF from (W/m2) to (micromol/m2/s)
      Q_DIR_2  = Q_DIR  * WM2_TO_UMOLM2S
      Q_DIFF_2 = Q_DIFF * WM2_TO_UMOLM2S

      !---------------------------------------------------
      ! Do only during day and over continent
      ! Only interested in terrestrial biosphere (pip)
      !---------------------------------------------------
      IF ( SUNCOS > 0d0 ) THEN

         IF ( ISOLAI(I,J) * AEF_ISOP(I,J) > 0d0 ) THEN

            IF ( LPECCA ) THEN 
                
               ! Activity factor for leaf area
               GAMMA_LAI = GET_GAMMA_LAI( MISOLAI(I,J) )


               ! Activity factor for light 
               GAMMA_P = GET_GAMMA_P_PECCA( I, J, Q_DIR_2, Q_DIFF_2,
     &                       PARDR_15_AVG(I,J), PARDF_15_AVG(I,J)  )

            ELSE 

               ! Using a canopy model set this to 1
               GAMMA_LAI = 1.0d0 

               ! Activity factor for light 
               GAMMA_P = GET_GAMMA_P( ISOLAI(I,J), SUNCOS,
     &                                 Q_DIR_2, Q_DIFF_2 )

            ENDIF

            ! Activity factor for leaf age 
            GAMMA_LEAF_AGE = GET_GAMMA_LEAF_AGE( MISOLAI(I,J), 
     &                                 PMISOLAI(I,J), D_BTW_M, 
     &                                'ISOP' , T_15_AVG(I,J) )

            ! Activity factor for temperature
            GAMMA_T = GET_GAMMA_T_ISOP( TS, T_15_AVG(I,J), 
     &                                      T_DAILY(I,J) )

            ! Activity factor for soil moisture
            GAMMA_SM = 1.d0

         ELSE

            ! If it's night or over ocean, set activity factors to zero
            GAMMA_T         = 0.d0
            GAMMA_LAI       = 0.d0
            GAMMA_LEAF_AGE  = 0.d0
            GAMMA_P         = 0.d0
            GAMMA_SM        = 0.d0

         ENDIF

         ! Isoprene emission is the product of all these
         EMISOP    = AEF_ISOP(I,J) * GAMMA_LAI * GAMMA_LEAF_AGE 
     &                             * GAMMA_T   * GAMMA_P  * GAMMA_SM  

         ! Convert from [kg/box] to [atoms C/box]
         EMISOP    = EMISOP * XNUMOL

      ENDIF

      END FUNCTION GET_EMISOP_MEGAN
!EOC
!------------------------------------------------------------------------------
!          Harvard University Atmospheric Chemistry Modeling Group            !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: get_emmbo_megan
!
! !DESCRIPTION: Subroutine GET\_EMMBO\_MEGAN computes methylbutenol emissions
!  in units of [atoms C/box] using the MEGAN inventory.
!\\
!\\
! !INTERFACE:
!
      FUNCTION GET_EMMBO_MEGAN( I,  J,      SUNCOS, 
     &                          TS, Q_DIR,  Q_DIFF, XNUMOL ) 
     &         RESULT( EMMBO )
!
! !USES:
!
      USE LAI_MOD,     ONLY : ISOLAI, MISOLAI, PMISOLAI, DAYS_BTW_M
      USE LOGICAL_MOD, ONLY : LPECCA 
!
! !INPUT PARAMETERS: 
!
      INTEGER, INTENT(IN) :: I, J    ! GEOS-Chem lon & lat indices
      REAL*8,  INTENT(IN) :: SUNCOS  ! Solar zenith angle [unitless]
      REAL*8,  INTENT(IN) :: TS      ! Surface temperature [K]
      REAL*8,  INTENT(IN) :: Q_DIR   ! Flux of direct PAR above canopy [W/m2]
      REAL*8,  INTENT(IN) :: Q_DIFF  ! Flux of diffuse PAR above canopy [W/m2]
      REAL*8,  INTENT(IN) :: XNUMOL  ! Number of atoms C / kg C 
!
! !RETURN VALUE:
!
      REAL*8              :: EMMBO   ! Methylbutenol emissions [atoms C/box]
! 
! !REMARKS:
!  References (see above for full citations):
!  ============================================================================
!  (1 ) Guenther et al, 1995, 1999, 2000, 2004, 2006
!  (2 ) Wang,    et al, 1998
!  (3 ) Guenther et al, 2007, MEGAN v2.1 User mannual 
!
! !REVISION HISTORY: 
!  (1 ) Original code by Dorian Abbot (9/2003).  Updated to the latest 
!        algorithm and modified for the standard code by May Fu (11/20/04)
!  (2 ) All MEGAN biogenic emission are currently calculated using TS from DAO 
!        met field. TS is the surface air temperature, which should be 
!        carefully distinguished from TSKIN. (tmf, 11/20/04)
!  (3 ) Restructing of function & implementation of activity factors (mpb,2009)
!  17 Dec 2009 - R. Yantosca - Added ProTeX headers
!EOP
!------------------------------------------------------------------------------
!BOC
!
! !LOCAL VARIABLES:
!
      REAL*8              :: GAMMA_LAI
      REAL*8              :: GAMMA_LEAF_AGE
      REAL*8              :: GAMMA_P
      REAL*8              :: GAMMA_T
      REAL*8              :: GAMMA_SM
      REAL*8              :: D_BTW_M, Q_DIR_2, Q_DIFF_2
      REAL*8, PARAMETER   :: BETA = 0.09

      !=================================================================
      ! GET_EMMBO_MEGAN begins here!
      !================================================================= 

      ! Initialize return value & activity factors
      EMMBO           = 0.d0
      GAMMA_T         = 0.d0
      GAMMA_LAI       = 0.d0
      GAMMA_LEAF_AGE  = 0.d0
      GAMMA_P         = 0.d0
      GAMMA_SM        = 0.d0

      ! Number of days between MISOLAI and PMISOLAI
      D_BTW_M  = DBLE( DAYS_BTW_M )

      ! Convert Q_DIR and Q_DIFF from [W/m2] to [umol/m2/s]
      Q_DIR_2  = Q_DIR  * WM2_TO_UMOLM2S
      Q_DIFF_2 = Q_DIFF * WM2_TO_UMOLM2S

      !-------------------------------------------------
      ! Do only during day and over continent
      ! Only interested in terrestrial biosphere (pip)
      !-------------------------------------------------
      IF ( SUNCOS > 0d0 ) THEN

         IF ( ISOLAI(I,J) * AEF_MBO(I,J) > 0d0 ) THEN

            IF ( LPECCA ) THEN 
                
               ! Activity factor for leaf area
               GAMMA_LAI = GET_GAMMA_LAI( MISOLAI(I,J) )

               ! Activity factor for light 
               GAMMA_P = GET_GAMMA_P_PECCA( I, J, Q_DIR_2, Q_DIFF_2,
     &                        PARDR_15_AVG(I,J), PARDF_15_AVG(I,J) )
            ELSE 

               ! Using a canopy model set this to 1
               GAMMA_LAI = 1.0d0 

               ! Activity factor for light 
               GAMMA_P = GET_GAMMA_P( ISOLAI(I,J), SUNCOS,
     &                                 Q_DIR_2, Q_DIFF_2 )
 
            ENDIF

            ! Activity factor for leaf age 
            GAMMA_LEAF_AGE = GET_GAMMA_LEAF_AGE( MISOLAI(I,J), 
     &                                 PMISOLAI(I,J), D_BTW_M, 
     &                                'MBOT' , T_15_AVG(I,J) )
         
            ! Activity factor for temperature
            GAMMA_T = GET_GAMMA_T_NISOP( TS, BETA )

            ! Activity factor for soil moisture
            GAMMA_SM = 1.d0

         ELSE

            ! If it's night or over ocean, set activity factors to zero
            GAMMA_T         = 0.d0
            GAMMA_LAI       = 0.d0
            GAMMA_LEAF_AGE  = 0.d0
            GAMMA_P         = 0.d0
            GAMMA_SM        = 0.d0

         ENDIF

         ! MBO emissions in [kg/box]
         EMMBO = AEF_MBO(I,J) * GAMMA_LAI * GAMMA_LEAF_AGE 
     &                        * GAMMA_T   * GAMMA_P * GAMMA_SM

         ! Convert from [atoms C/box] to [kg/box]
         EMMBO = EMMBO * XNUMOL

      ENDIF

      END FUNCTION GET_EMMBO_MEGAN
!EOC
!------------------------------------------------------------------------------
!          Harvard University Atmospheric Chemistry Modeling Group            !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: get_emmonog_megan
!
! !DESCRIPTION: Subroutine GET\_EMMONOG\_MEGAN computes generic ('G') 
!  monoterpene emissions for individual monoterpene species in units of 
!  [atoms C/box] using the new v2.1 MEGAN inventory emission factor maps.
!\\
!\\
! !INTERFACE:
!
      FUNCTION GET_EMMONOG_MEGAN( I,     J,      SUNCOS, TS, 
     &                            Q_DIR, Q_DIFF, XNUMOL, MONO_SPECIES ) 
     &            RESULT( EMMONOT )
!
! !USES:
!
      USE LAI_MOD,     ONLY : ISOLAI, MISOLAI, PMISOLAI, DAYS_BTW_M
      USE LOGICAL_MOD, ONLY : LPECCA 
!
! !INPUT PARAMETERS: 
!
      INTEGER,          INTENT(IN) :: I, J          ! Lon & lat indices
      REAL*8,           INTENT(IN) :: SUNCOS        ! Cos(solar zenith angle)
      REAL*8,           INTENT(IN) :: TS            ! Surface temperature [K]
      REAL*8,           INTENT(IN) :: Q_DIR         ! Direct PAR [W/m2]
      REAL*8,           INTENT(IN) :: Q_DIFF        ! Diffuse PAR [W/m2]
      REAL*8,           INTENT(IN) :: XNUMOL        ! Number of atoms C / kg C 
      CHARACTER(LEN=5), INTENT(IN) :: MONO_SPECIES  ! Monoterpene species name
!
! !RETURN VALUE:
!
      REAL*8                       :: EMMONOT       ! Emissions [atoms C/box]
!
! !REMARKS:
!  References (see above for full citations):
!  ============================================================================
!  (1 ) Guenther et al, 1995, 1999, 2004, 2006
!  (2 ) Guenther et al, 2007, MEGAN v2.1 User Manual
! 
! !REVISION HISTORY: 
!  (1 ) Written by Michael Barkley (2008), based on old monoterpene code by 
!       dsa,tmf.
!  (2 ) Uses gamma factors instead of exchange factors, this includes
!        calling of a new temperature algorithm which use a beta factor.
!        (mpb,2008)
!  17 Dec 2009 - R. Yantosca - Added ProTeX headers
!EOP
!------------------------------------------------------------------------------
!BOC
!
! !DEFINED PARAMETERS:
!
      REAL*8, PARAMETER :: BETA = 0.09
!
! !LOCAL VARIABLES:
!
      INTEGER           :: IJLOOP
      REAL*8            :: GAMMA_LAI
      REAL*8            :: GAMMA_LEAF_AGE
      REAL*8            :: GAMMA_P
      REAL*8            :: GAMMA_T
      REAL*8            :: GAMMA_SM
      REAL*8            :: D_BTW_M
      REAL*8            :: LDF 
      REAL*8            :: Q_DIR_2, Q_DIFF_2
      ! bug fix: need local AEF_SPARE (hotp 3/10/10)
      ! AEF_SPARE is a scaler
      REAL*8              :: AEF_SPARE

      !=================================================================
      ! GET_EMMONOT_MEGAN begins here!
      !================================================================= 

      ! Initialize return value & activity factors
      EMMONOT         = 0.d0
      GAMMA_T         = 0.d0
      GAMMA_LAI       = 0.d0
      GAMMA_LEAF_AGE  = 0.d0
      GAMMA_P         = 0.d0
      GAMMA_SM        = 0.d0
      AEF_SPARE       = 0.d0

      ! Number of days between MISOLAI and PMISOLAI
      D_BTW_M  = DBLE( DAYS_BTW_M )

      ! Convert Q_DIR and Q_DIFF from [W/m2] to [umol/m2/s]
      Q_DIR_2  = Q_DIR  * WM2_TO_UMOLM2S
      Q_DIFF_2 = Q_DIFF * WM2_TO_UMOLM2S

      ! Need to determine which monoterpene AEFs 
      ! we need to use (mpb,2009)
      SELECT CASE( MONO_SPECIES) 
      CASE( 'APINE' )
         AEF_SPARE = AEF_APINE(I,J) ! hotp add I,J (3/10/10)
         LDF       = 0.1
      CASE( 'BPINE' )
         AEF_SPARE = AEF_BPINE(I,J) ! hotp add I,J (3/10/10)
         LDF       = 0.1
      CASE( 'LIMON' )
         AEF_SPARE = AEF_LIMON(I,J) ! hotp add I,J (3/10/10)
         LDF       = 0.05
      CASE( 'SABIN' )
         AEF_SPARE = AEF_SABIN(I,J) ! hotp add I,J (3/10/10)
         LDF       = 0.1
      CASE( 'MYRCN' )
         AEF_SPARE = AEF_MYRCN(I,J) ! hotp add I,J (3/10/10)
         LDF       = 0.05
      CASE( 'CAREN' )
         AEF_SPARE = AEF_CAREN(I,J) ! hotp add I,J (3/10/10)
         LDF       = 0.05
      CASE( 'OCIMN' )
         AEF_SPARE = AEF_OCIMN(I,J) ! hotp add I,J (3/10/10)
         LDF       = 0.8
      CASE DEFAULT
         CALL ERROR_STOP( 'Invalid MONOTERPENE species', 
     &                    'GET_EMMONOG_MEGAN (megan_mod.f)' )
      END SELECT   

      !-----------------------------------------------------
      ! Only interested in terrestrial biosphere (pip)
      ! If (local LAI != 0 .AND. baseline emission !=0 ) 
      !-----------------------------------------------------
      ! AEF_SPARE no longer I,J (hotp 3/10/10)
      !IF ( ISOLAI(I,J) * AEF_SPARE(I,J) > 0d0 ) THEN
      IF ( ISOLAI(I,J) * AEF_SPARE > 0d0 ) THEN

            ! Calculate gamma PAR only if sunlight conditions
            IF ( SUNCOS > 0d0 ) THEN

               IF ( LPECCA ) THEN 
               
                  GAMMA_P = GET_GAMMA_P_PECCA(I, J, Q_DIR_2, Q_DIFF_2,
     &                         PARDR_15_AVG(I,J),  PARDF_15_AVG(I,J) )
               ELSE 
  
                  GAMMA_P = GET_GAMMA_P( ISOLAI(I,J), SUNCOS,
     &                                    Q_DIR_2, Q_DIFF_2 )
               END IF 

            ELSE             
 
               ! If night
               GAMMA_P = 0.d0  
           
            END IF

            ! Activity factor for leaf area
            GAMMA_LAI = GET_GAMMA_LAI( MISOLAI(I,J) )

            ! Activity factor for leaf age 
            GAMMA_LEAF_AGE = GET_GAMMA_LEAF_AGE( MISOLAI(I,J), 
     &                                 PMISOLAI(I,J), D_BTW_M, 
     &                                 'MONO', T_15_AVG(I,J) )

            ! Activity factor for temperature
            GAMMA_T = GET_GAMMA_T_NISOP( TS, BETA )

            ! Activity factor for soil moisture
            GAMMA_SM = 1.d0

         ELSE

            ! set activity factors to zero
            GAMMA_T         = 0.d0
            GAMMA_LAI       = 0.d0
            GAMMA_LEAF_AGE  = 0.d0
            GAMMA_P         = 0.d0
            GAMMA_SM        = 0.d0

      END IF
    
      ! Monoterpene emission is the product of all these; must be 
      ! careful to distinguish between canopy & PECCA models.
      IF ( LPECCA ) THEN
         ! removed I,J from AEF_SPARE (hotp 3/10/10)
         !EMMONOT    = AEF_SPARE(I,J) * GAMMA_LEAF_AGE * GAMMA_T 
         EMMONOT    = AEF_SPARE * GAMMA_LEAF_AGE * GAMMA_T 
     &                               * GAMMA_SM       * GAMMA_LAI
     &                       * ( (1.d0 - LDF) + (LDF * GAMMA_P) )

      ELSE 

         ! removed I,J from AEF_SPARE (hotp 3/10/10)
         !EMMONOT    = AEF_SPARE(I,J) * GAMMA_LEAF_AGE * GAMMA_T
         EMMONOT    = AEF_SPARE * GAMMA_LEAF_AGE * GAMMA_T 
     &                               * GAMMA_SM       
     &                * (  GAMMA_LAI * (1.d0 - LDF) + (LDF * GAMMA_P) )

      END IF 

      ! Convert from [kg/box] to [atoms C/box]
      EMMONOT  = EMMONOT * XNUMOL

      END FUNCTION GET_EMMONOG_MEGAN
!EOC
!------------------------------------------------------------------------------
!          Harvard University Atmospheric Chemistry Modeling Group            !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: get_emmonot_megan
!
! !DESCRIPTION: Subroutine GET\_EMMONOT\_MEGAN computes the total 
!  monoterpene emissions in units of [atoms C/box] using the MEGAN v2.1 
!  inventory.
!\\
!\\
! !INTERFACE:
!
      FUNCTION GET_EMMONOT_MEGAN( I,  J,     SUNCOS, 
     &                            TS, Q_DIR, Q_DIFF, XNUMOL ) 
     &            RESULT( EMMONOT )
!
! !USES:
!
      USE LAI_MOD,    ONLY : ISOLAI, MISOLAI, PMISOLAI, DAYS_BTW_M
!
! !INPUT PARAMETERS: 
!
      INTEGER, INTENT(IN) :: I, J      ! Lon & lat indices
      REAL*8,  INTENT(IN) :: SUNCOS    ! Cos( solar zenith angle ) 
      REAL*8,  INTENT(IN) :: TS        ! Local surface air temperature [K]
      REAL*8,  INTENT(IN) :: Q_DIR     ! Direct PAR above canopy [W/m2]
      REAL*8,  INTENT(IN) :: Q_DIFF    ! Diffuse PAR above canopy [W/m2]
      REAL*8,  INTENT(IN) :: XNUMOL    ! Number of atoms C / kg C 
!
! !RETURN VALUE:
!
      REAL*8              :: EMMONOT   ! Monoterpene emissions [atoms C/box]
!
! !REMARKS:
!  References (see above for full citations):
!  ============================================================================
!  (1 ) Guenther et al, 1995, 1999, 2000, 2006
!  (2 ) Guenther et al, 2007, MEGAN v2.1 User Manual
! 
! !REVISION HISTORY: 
!  (1 ) Original code by Michael Barkley (mpb,2009).
!  17 Dec 2009 - R. Yantosca - Added ProTeX headers
!  09 Mar 2010 - H.O.T. Pye  - Change order of arguments in call to 
!                              routine GET_EMMONOG_MEGAN
!EOP
!------------------------------------------------------------------------------
!BOC
!
! !LOCAL VARIABLES:
!
      REAL*8                        :: MONO
      INTEGER                       :: K 
      INTEGER, PARAMETER            :: N = 7
      CHARACTER(LEN=5),DIMENSION(7) :: SPECIES      
      SPECIES = ( / 'APINE' , 'BPINE' , 'LIMON' , 'SABIN' , 'MYRCN' ,
     &            'CAREN' , 'OCIMN' / )

      !=================================================================
      ! GET_EMMONOT_MEGAN begins here!
      !================================================================= 

      ! Initialize
      EMMONOT = 0.d0

      DO K = 1 , N
         MONO = GET_EMMONOG_MEGAN( I , J , SUNCOS, TS , Q_DIR ,
     &                             Q_DIFF , XNUMOL , SPECIES(K) ) 

         EMMONOT = EMMONOT + MONO
      ENDDO

      END FUNCTION GET_EMMONOT_MEGAN
!EOC
!------------------------------------------------------------------------------
!          Harvard University Atmospheric Chemistry Modeling Group            !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: activity_factors
!
! !DESCRIPTION: Subroutine ACTIVITY\_FACTORS computes the gamma activity 
!  factors which adjust the emission factors to the current weather and 
!  vegetation conditions.  Here they are calculated by (default) for isoprene. 
!\\
!\\
! !INTERFACE:
!
      SUBROUTINE ACTIVITY_FACTORS( I,              J,       TS,     
     &                             SUNCOS,         Q_DIR,   Q_DIFF, 
     &                             XNUMOL,         SPECIES, GAMMA_LAI, 
     &                             GAMMA_LEAF_AGE, GAMMA_P, GAMMA_T, 
     &                             GAMMA_SM )
!
! !USES:
!
      USE LAI_MOD,     ONLY : ISOLAI, MISOLAI, PMISOLAI, DAYS_BTW_M
      USE LOGICAL_MOD, ONLY : LPECCA 
!
! !INPUT PARAMETERS: 
!
      INTEGER,          INTENT(IN)   :: I, J     ! Lon & lat indices
      REAL*8,           INTENT(IN)   :: SUNCOS   ! Cos( solar zenith angle ) 
      REAL*8,           INTENT(IN)   :: TS       ! Surface air temperature [K]
      REAL*8,           INTENT(IN)   :: XNUMOL   ! Number of atoms C / kg C 
      REAL*8,           INTENT(IN)   :: Q_DIR    ! Direct PAR [W/m2]
      REAL*8,           INTENT(IN)   :: Q_DIFF   ! Diffuse PAR [W/m2]
      CHARACTER(LEN=4), INTENT(IN)   :: SPECIES  ! Species (ISOP,MONO,MBOT)
!
! !OUTPUT PARAMETERS:
!
      ! GAMMA factors for:
      REAL*8,           INTENT(OUT)  :: GAMMA_LAI       ! LAI
      REAL*8,           INTENT(OUT)  :: GAMMA_LEAF_AGE  ! Leaf age
      REAL*8,           INTENT(OUT)  :: GAMMA_P         ! Light
      REAL*8,           INTENT(OUT)  :: GAMMA_T         ! Temperature
      REAL*8,           INTENT(OUT)  :: GAMMA_SM        ! Soil moisture
!
! !REVISION HISTORY: 
!  (1 ) Original code written by Michael Barkley (mpb,2009).
!  17 Dec 2009 - R. Yantosca - Added ProTeX headers
!EOP
!------------------------------------------------------------------------------
!BOC
!
! !LOCAL VARIABLES:
!
      INTEGER             :: IJLOOP
      REAL*8              :: D_BTW_M, Q_DIR_2, Q_DIFF_2
      REAL*8, PARAMETER   :: BETA = 0.09

      !=================================================================
      ! ACTIVITY_FACTORS begins here!
      !================================================================= 

      ! Initialize
      GAMMA_T         = 0.d0
      GAMMA_LAI       = 0.d0
      GAMMA_LEAF_AGE  = 0.d0
      GAMMA_P         = 0.d0
      GAMMA_SM        = 0.d0

      ! Number of days between MISOLAI and PMISOLAI
      D_BTW_M  = DBLE( DAYS_BTW_M )

      ! 1-D array index
      IJLOOP   = ( (J-1) * IIPAR ) + I
      
      ! Convert Q_DIR and Q_DIFF from (W/m2) to (micromol/m2/s)
      Q_DIR_2  = Q_DIR  * WM2_TO_UMOLM2S
      Q_DIFF_2 = Q_DIFF * WM2_TO_UMOLM2S

      !---------------------------------------------------
      ! Do only during day and over continent
      ! Only interested in terrestrial biosphere (pip)
      !---------------------------------------------------
      IF ( SUNCOS > 0d0 ) THEN

         IF ( ISOLAI(I,J) * AEF_ISOP(I,J) > 0d0 ) THEN

            IF ( LPECCA ) THEN 
                
               ! Activity factor for leaf area
               GAMMA_LAI = GET_GAMMA_LAI( MISOLAI(I,J) )

               ! Activity factor for light 
               GAMMA_P = GET_GAMMA_P_PECCA( I, J, Q_DIR_2, Q_DIFF_2,
     &                        PARDR_15_AVG(I,J), PARDF_15_AVG(I,J) )
            ELSE 

               ! Using a canopy model set this to 1
               GAMMA_LAI = 1.0d0 

               ! Activity factor for light 
               GAMMA_P = GET_GAMMA_P( ISOLAI(I,J), SUNCOS,
     &                                 Q_DIR_2, Q_DIFF_2 )
 
            ENDIF

            ! Activity factor for leaf age 
            GAMMA_LEAF_AGE = GET_GAMMA_LEAF_AGE( MISOLAI(I,J), 
     &                                 PMISOLAI(I,J), D_BTW_M, 
     &                                'ISOP' , T_15_AVG(I,J) )
         
            ! Activity factor for temperature
            GAMMA_T = GET_GAMMA_T_ISOP( TS, T_15_AVG(I,J), 
     &                                      T_DAILY(I,J) )

            ! Activity factor for soil moisture
            GAMMA_SM = 1.d0

         ELSE

            ! If it's night or over ocean, set activity factors to zero
            GAMMA_T         = 0.d0
            GAMMA_LAI       = 0.d0
            GAMMA_LEAF_AGE  = 0.d0
            GAMMA_P         = 0.d0
            GAMMA_SM        = 0.d0

         ENDIF

      ENDIF

      END SUBROUTINE ACTIVITY_FACTORS
!EOC
!------------------------------------------------------------------------------
!          Harvard University Atmospheric Chemistry Modeling Group            !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: get_gamma_p_pecca
!
! !DESCRIPTION: Computes the PECCA gamma activity factor with sensitivity 
!  to LIGHT.
!\\
!\\
! !INTERFACE:
!
      FUNCTION GET_GAMMA_P_PECCA( I , J , Q_DIR_2, Q_DIFF_2 ,
     &                            PARDR_AVG_SIM ,  PARDF_AVG_SIM  )
     &              RESULT( GAMMA_P_PECCA )
!
! !USES:
!
      USE TIME_MOD,   ONLY : GET_DAY_OF_YEAR
      USE TIME_MOD,   ONLY : GET_LOCALTIME
      USE GRID_MOD,   ONLY : GET_YMID  

#     include "CMN_GCTM"   ! Physical constants (why?!)
!
! !INPUT PARAMETERS: 
!
      INTEGER, INTENT(IN) :: I,  J             ! Lon & lat indices 
      REAL*8,  INTENT(IN) :: PARDR_AVG_SIM     ! Average direct PAR [W/m2]
      REAL*8,  INTENT(IN) :: PARDF_AVG_SIM     ! Average diffuse PAR [W/m2]
      REAL*8,  INTENT(IN) :: Q_DIR_2           ! Direct PAR [umol/m2/s]
      REAL*8,  INTENT(IN) :: Q_DIFF_2          ! Diffuse PAR [umol/m2/s]
!
! !RETURN VALUE:
!
      REAL*8              :: GAMMA_P_PECCA     ! GAMMA factor for light
!
! !REMARKS:
!  References (see above for full citations):
!  ============================================================================
!  (1 ) Guenther et al, 2006
!  (2 ) Guenther et al, 2007, MEGAN v2.1 user guide
! 
! !REVISION HISTORY: 
!  (1 ) Here PAR*_AVG_SIM is the average light conditions over the simulation 
!       period. I've set this = 10 days to be consistent with temperature & as 
!       outlined in Guenther et al, 2006. (mpb,2009)
!  (2 ) Code was taken & adapted directly from the MEGAN v2.1 source code.
!       (mpb,2009)
!  17 Dec 2009 - R. Yantosca - Added ProTeX headers
!EOP
!------------------------------------------------------------------------------
!BOC
!
! !LOCAL VARIABLES:
!
      REAL*8              :: LUT , LAT 
      REAL*8              :: mmPARDR_DAILY
      REAL*8              :: mmPARDF_DAILY
      REAL*8              :: PAC_DAILY, PAC_INSTANT, C_PPFD
      REAL*8              :: PTOA, PHI
      REAL*8              :: BETA,   SINbeta 
      INTEGER             :: DOY 
      REAL*8              :: AAA, BBB

      !-----------------------------------------------------------------
      ! Compute GAMMA_P_PECCA
      !-----------------------------------------------------------------  

      ! Initialize
      C_PPFD   = 0.0d0
      PTOA     = 0.0d0

      ! Convert past light conditions to micromol/m2/s 
      mmPARDR_DAILY   = PARDR_AVG_SIM  * WM2_TO_UMOLM2S
      mmPARDF_DAILY   = PARDF_AVG_SIM  * WM2_TO_UMOLM2S

      ! Work out the light at the top of the canopy.
      PAC_DAILY    = mmPARDR_DAILY + mmPARDF_DAILY
      PAC_INSTANT  = Q_DIR_2       +  Q_DIFF_2

      ! Get day of year, local-time and latitude
      DOY   = GET_DAY_OF_YEAR()
      LUT   = GET_LOCALTIME( I )
      LAT   = GET_YMID( J )

      ! Get solar elevation angle
      SINbeta      =  SOLAR_ANGLE( DOY , LUT , LAT  )
      BETA         =  ASIN( SINbeta ) * RAD2D       

      IF ( SINbeta .LE. 0.0d0 ) THEN

         GAMMA_P_PECCA = 0.0d0

      ELSEIF ( SINbeta .GT. 0.0d0 ) THEN       

         ! PPFD at top of atmosphere
         PTOA    = 3000.0d0 + 99.0d0 * 
     &             COS( 2.d0 * 3.14d0 *( DOY - 10 ) / 365 )

         ! Above canopy transmission
         PHI     = PAC_INSTANT / ( SINbeta * PTOA )

         ! Work out gamma P
         BBB     = 1.0d0 + 0.0005d0 *( PAC_DAILY - 400.0d0  ) 
         AAA     = ( 2.46d0 * BBB * PHI ) - ( 0.9d0 * PHI**2 )

         GAMMA_P_PECCA = SINbeta * AAA

      ENDIF

       ! Screen unforced errors. IF solar elevation angle is 
       ! less than 1 THEN gamma_p can not be greater than 0.1.
       IF ( BETA .LT. 1.0 .AND. GAMMA_P_PECCA .GT. 0.1) THEN
          GAMMA_P_PECCA  = 0.0
       ENDIF
   
      ! Prevent negative values
      GAMMA_P_PECCA = MAX( GAMMA_P_PECCA , 0d0 )

      END FUNCTION GET_GAMMA_P_PECCA
!EOC
!------------------------------------------------------------------------------
!          Harvard University Atmospheric Chemistry Modeling Group            !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: solar_angle
!
! !DESCRIPTION: Function SOLAR\_ANGLE computes the local solar angle for a 
!  given day of year, latitude and longitude (or local time).  Called from  
!  routine GAMMA\_P\_PECCA.
!\\
!\\
! !INTERFACE:
!
      FUNCTION SOLAR_ANGLE( DOY, SHOUR, LAT ) RESULT( SINbeta )
!
! !USES:
!

!
! !INPUT PARAMETERS: 
!
      ! Arguments
      INTEGER, INTENT(IN) :: DOY       ! Day of year
      REAL*8,  INTENT(IN) :: SHOUR     ! Local time 
      REAL*8,  INTENT(IN) :: LAT       ! Latitude
!
! !RETURN VALUE:
!
      REAL*8              :: SINbeta   ! Sin of the local solar angle
!
! !REMARKS:
!  References (see above for full citations):
!  (1 ) Guenther et al, 2006
!  (2 ) Guenther et al, MEGAN v2.1 user mannual 2007-09
! 
! !REVISION HISTORY: 
!  (1 ) This code was taken directly from the MEGAN v2.1 source code.(mpb,2009)
!  17 Dec 2009 - R. Yantosca - Added ProTeX headers
!EOP
!------------------------------------------------------------------------------
!BOC
!
! !LOCAL VARIABLES:
!
      ! Local variables
      REAL*8    :: BETA                 ! solar elevation angle
      REAL*8    :: sindelta, cosdelta, A, B

      ! Calculation of sin beta 
      sindelta = -SIN( 0.40907d0 ) * 
     &            COS( 6.28d0 * ( DOY + 10 ) / 365 )

      cosdelta = (1-sindelta**2.)**0.5

      A = SIN( LAT * D2RAD ) * sindelta
      B = COS( LAT * D2RAD ) * cosdelta

      SINbeta = A + B * COS( 2.0d0 * PI * ( SHOUR-12 ) / 24 ) 

      END FUNCTION SOLAR_ANGLE 
!EOC
!------------------------------------------------------------------------------
!          Harvard University Atmospheric Chemistry Modeling Group            !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: get_gamma_t_isop
!
! !DESCRIPTION: Function GET\_GAMMA\_T\_ISOP computes the temperature 
!  sensitivity for ISOPRENE ONLY.
!\\
!\\
! !INTERFACE:
!
      FUNCTION GET_GAMMA_T_ISOP( T, PT_15, PT_1 ) RESULT( GAMMA_T )
!
! !INPUT PARAMETERS: 
!

      ! Current leaf temperature, the surface air temperature field (TS) 
      ! is assumed equivalent to the leaf temperature over forests.
      REAL*8,  INTENT(IN) :: T 

 
      ! Average leaf temperature over the past 15 days
      REAL*8,  INTENT(IN) :: PT_15

      ! Average leaf temperature over the past arbitray day(s).
      ! This is not used at present (but might be soon!).
      REAL*8,  INTENT(IN) :: PT_1
!
! !RETURN VALUE:
!
      ! GAMMA factor for temperature (isoprene only)
      REAL*8              :: GAMMA_T
!
! !REMARKS:
!  References (see above for full citations):
!  ============================================================================
!  (1 ) Guenther et al, 1995
!  (2 ) Guenther et al, 2006
!  (3 ) Guenther et al, MEGAN v2.1 user mannual 2007-08
! 
! 
! !REVISION HISTORY: 
!  (1 ) Includes the latest MEGAN v2.1 temperature algorithm (mpb, 2009).
!       Note, this temp-dependence is the same for the PECCA & hybrid models.
!  17 Dec 2009 - R. Yantosca - Added ProTeX headers
!EOP
!------------------------------------------------------------------------------
!BOC
!
! !LOCAL VARIABLES:
!
      REAL*8              :: C_T,   CT1,   CT2
      REAL*8              :: E_OPT, T_OPT, X

      ! Ideal gas constant [J/mol/K]
      REAL*8, PARAMETER   :: R   = 8.314d-3


      ! Normalization Factor 
      REAL*8, PARAMETER   ::  NORM = 0.99558166894501043d0    
                                   
      !=================================================================!
      !             ALWAYS CHECK THE ABOVE NORMALIZATION                !
      !=================================================================!
       E_OPT = 1.75d0 * EXP( 0.08d0 * ( PT_15  - 2.97d2 ) )     
       T_OPT = 3.13d2 + ( 6.0d-1 * ( PT_15 - 2.97d2 ) )
       CT1   = 80d0
       CT2   = 200d0

      ! Variable related to temperature 
      X     = ( 1.d0/T_OPT - 1.d0/T ) / R

      ! C_T: Effect of temperature on leaf BVOC emission, including 
      ! effect of average temperature over previous 15 days, based on 
      ! Eq 5a, 5b, 5c from Guenther et al, 1999.
      C_T   = E_OPT * CT2 * EXP( CT1 * X ) / 
     &        ( CT2 - CT1 * ( 1.d0 - EXP( CT2 * X ) ) )

      ! Hourly emission activity = C_T
      ! Prevent negative values
      GAMMA_T = MAX( C_T * NORM , 0d0 )

      END FUNCTION GET_GAMMA_T_ISOP
!EOC
!------------------------------------------------------------------------------
!          Harvard University Atmospheric Chemistry Modeling Group            !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: get_gamma_t_nisop
!
! !DESCRIPTION: Function GET\_GAMMA\_T\_NISOP computes the temperature 
!  activity factor (GAMMA\_T) for BVOCs OTHER than isoprene.  Called from 
!  routines GET\_EMMONOG\_MEGAN and GET\_EMMBO\_MEGAN.
!\\
!\\
! !INTERFACE:
!
      FUNCTION GET_GAMMA_T_NISOP( T, BETA ) RESULT( GAMMA_T )
!
! !INPUT PARAMETERS: 
!
      ! Current leaf temperature [K], the surface air temperature field (TS) 
      ! is assumed equivalent to the leaf temperature over forests.
      REAL*8, INTENT(IN) :: T        

      ! Temperature factor per species (from MEGAN user manual). 
      ! Beta = 0.09 for MBO and for monoterpene species (APINE, BPINE, LIMON, 
      ! SABIN, MYRCN, CAREN, OCIMN). Pass as an argument in case this changes.
      REAL*8, INTENT(IN) :: BETA     
!
! !RETURN VALUE:
!
      REAL*8             :: GAMMA_T  ! 
!
! !REMARKS:
!  GAMMA_T =  exp[BETA*(T-Ts)]
!                                                                             .
!             where BETA   = temperature dependent parameter
!                   Ts     = standard temperature (normally 303K, 30C)
!                                                                             .
!  References (see above for full citations):
!  ============================================================================
!  (1 ) Guenther et al, 2006
!  (2 ) Guenther et al, MEGAN user mannual 2007-08

! !REVISION HISTORY: 
!  (1 ) Original code by Michael Barkley (2009).
!       Note: If T = Ts  (i.e. standard conditions) then GAMMA_T = 1 
!  17 Dec 2009 - R. Yantosca - Added ProTeX headers
!EOP
!------------------------------------------------------------------------------
!BOC
!
! !DEFINED PARAMETERS:
!
      ! Standard reference temperature [K]
      REAL*8, PARAMETER   :: Ts = 303.0

      !=================================================================
      ! GET_GAMMAT_NISOP begins here!
      !================================================================= 

      GAMMA_T = EXP( BETA * ( T - Ts ) )

      END FUNCTION GET_GAMMA_T_NISOP
!EOC
!------------------------------------------------------------------------------
!          Harvard University Atmospheric Chemistry Modeling Group            !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: get_gamma_p
!
! !DESCRIPTION: Function GET\_GAMMA\_P computes the gamma activity factor with
!  sensitivity to LIGHT (aka 'PAR').  Called by the functions !
!  GET\_EMISOP\_MEGAN, GET\_EMMBO\_MEGAN, and GET\_EMMONOG\_MEGAN.
!\\
!\\
! !INTERFACE:
!
      FUNCTION GET_GAMMA_P( LAI, SUNCOS1, Q_DIR_2, Q_DIFF_2 ) 
     &              RESULT( GAMMA_P )
!
! !USES:
!
#     include "CMN_GCTM"   ! Physical constants
!
! !INPUT PARAMETERS: 
!
      REAL*8,  INTENT(IN) :: LAI        ! Cumulative leaf area index 
      REAL*8,  INTENT(IN) :: SUNCOS1    ! Cosine of solar zenith angle 
      REAL*8,  INTENT(IN) :: Q_DIR_2    ! Direct PAR above canopy [umol/m2/s]
      REAL*8,  INTENT(IN) :: Q_DIFF_2   ! Diffuse PAR above canopy [umol/m2/s]
!
! !RETURN VALUE:
!
      REAL*8              :: GAMMA_P    ! Gamma activity factor w/r/t light
!
! !REMARKS:
!  *** REVAMPED FUNCTION ***
!                                                                             .
!  C_PPFD: Effect of increasing PPFD up to a saturation point, where emission 
!          level off, based on Eq 4abc from Guenther et al. (1999)
!          In addition, a 5 layered canopy model based on Eqs 12-16 
!          from Guenther et al. (1995) is included to correct for light 
!          attenuation in the canopy.
!                                                                             .
!  References (see above for full citations):
!  ============================================================================
!  (1 ) Guenther et al, 1995
!  (2 ) Wang     et al, 1998
!  (3 ) Guenther et al, 1999
!  (5 ) Guenther et al, 2004
! 
! !REVISION HISTORY: 
!  (1 ) Original code by Dorian Abbot and by May Fu.
!  (2 ) This code was extracted from the previous GET_HEA_TL function. 
!       (mpb,2009)
!  17 Dec 2009 - R. Yantosca - Added ProTeX headers
!EOP
!------------------------------------------------------------------------------
!BOC
!
! !LOCAL VARIABLES:
!
      !-----------------------------------------------------------------
      ! Canopy model variables (Eqs 12-16 from Guenther et al, 1995)
      !-----------------------------------------------------------------


      ! C_PPFD: Effect of increasing PPFD up to a saturation point, where 
      ! emissions level off, based on Eq 4abc from Guenther et al. (1999)
      ! In addition, a 5 layered canopy model based on Eqs 12-16 
      ! from Guenther et al. (1995) is included to correct for light 
      ! attenuation in the canopy.
      REAL*8              :: C_PPFD

      ! LAYERS: number of layers in canopy model
      INTEGER, PARAMETER  :: LAYERS = 5

      ! A: mean leaf-Sun angle, 60 degrees represents a 
      !    spherical leaf angle distribution
      REAL*8,  PARAMETER  :: A = 6.0d1 * PI / 1.8d2 

      ! WEIGHTGAUSS : weights for gaussian integration
      REAL*8,  PARAMETER  :: WEIGHTGAUSS(LAYERS) = (/ 1.1846d-1, 
     &                                                2.3931d-1, 
     &                                                2.8444d-1, 
     &                                                2.3931d-1, 
     &                                                1.1846d-1 /)

      ! DISTGAUSS: points to evaluate fcn for gaussian integration
      REAL*8,  PARAMETER  :: DISTGAUSS(LAYERS)   = (/ 4.6910d-2, 
     &                                                2.3075d-1, 
     &                                                5.0000d-1, 
     &                                                7.6924d-1, 
     &                                                9.5308d-1 /)

      ! SCAT: Scattering coefficient
      REAL*8, PARAMETER   :: SCAT = 2.0d-1

      ! REFLD: Reflection coefficient for diffuse light
      REAL*8, PARAMETER   :: REFLD = 5.7d-2

      ! CLUSTER: clustering coefficient (accounts for leaf clumping 
      ! influence on mean projected leaf area in the direction 
      ! of the sun's beam) use 0.85 for default
      REAL*8, PARAMETER   :: CLUSTER = 8.5d-1

      ! NORMAL_FACTOR : C_PPFD calculated with LAI = 5, and above canopy 
      ! total PPFD = 1500 umol/m2/s, and Q_DIFF = 0.2 * above canopy total 
      ! PPFD.  May Fu calculated this to be 1.8967d0
      ! Quickly checked by mpb in 2008 & found to be:
      REAL*8, PARAMETER   :: NORMAL_FACTOR = 1.80437817285271950d0

      ! F_SUN: Fraction leaves sunlit
      REAL*8              :: F_SUN

      ! F_SHADE: Fraction leaves shaded
      REAL*8              :: F_SHADE

      ! LAI_DEPTH: Cumulative LAI above current layer
      REAL*8              :: LAI_DEPTH

      ! Q_SUN: Flux density of PAR on sunny leaves [umol/m2/s]
      REAL*8              :: Q_SUN
 
      ! Q_SHADE: Flux density of PAR on shaded leaves [umol/m2/s]
      REAL*8              :: Q_SHADE, Q_SHADE_1, Q_SHADE_2

      ! KB: Extinction coefficient for black leaves for direct (beam)
      REAL*8              :: KB, KBP

      ! KD: Extinction coefficient for black leaves for diffuse light
      REAL*8              :: KD,   KDP
      REAL*8              :: REFLB

      ! C_P_SUN: C_PPFD at layer I for sunlit leaves
      REAL*8              :: C_P_SUN
      
      ! C_P_SHADE: C_PPFD at layer I for shaded leaves
      REAL*8              :: C_P_SHADE

      ! C_PPFD_I    : C_PPFD at layer I
      REAL*8              :: C_PPFD_I

      ! Empirical functions (Eq 4a, 4b, 4c from Guenther et al, 1999)
      REAL*8              :: ALPHA, CL

      ! ??
      REAL*8              :: P

      ! Index for layers
      INTEGER             :: I

      !-----------------------------------------------------------------
      ! Compute C_PPFD
      !-----------------------------------------------------------------  

      ! Initialize
      C_PPFD  = 0.d0

      ! 0.5 and 0.8 assume a spherical leaf-angle distribution
      KB      = 0.5d0 * CLUSTER / SUNCOS1
      KD      = 0.8d0 * CLUSTER
      P       = SQRT( 1.d0 - SCAT )
      REFLB   = 1.d0 - 
     &          EXP(-2.d0*KB * ( 1.d0-P ) / ( 1.d0+P ) / ( 1.d0+KB ) )
      KBP     = KB * P
      KDP     = KD * P

      ! 5-layer Gaussian integration over canopy
      DO I = 1, LAYERS 

         ! Cumulative LAI above layer I
         LAI_DEPTH  = LAI * DISTGAUSS( I )

         ! Fraction sun and shade leaves at layer I
         F_SUN      = EXP( -KB * LAI_DEPTH ) 
         F_SHADE    = 1.d0 - F_SUN

         ! For PAR on shaded leaves
         Q_SHADE_1  = Q_DIFF_2 * KDP * ( 1.d0 - REFLD ) *
     &                EXP( -KDP * LAI_DEPTH ) 

         ! For PAR on shaded leaves
         Q_SHADE_2  = Q_DIR_2 * ( KBP * ( 1.d0 - REFLB ) * 
     &                EXP( -KBP * LAI_DEPTH ) - KB * ( 1.d0 - SCAT ) * 
     &                EXP( -KB * LAI_DEPTH ) )

         ! PAR on shaded leaves
         Q_SHADE    = ( Q_SHADE_1 + Q_SHADE_2 ) / ( 1.d0 - SCAT )

         ! PAR on sunlit leaves
         Q_SUN      = Q_SHADE + KB * Q_DIR_2

         ! Update C_P_SUN and C_P_SHADE at layer I
         ! The following already accounts for canopy attenuation
         ! (Guenther et al, 1999)
         ALPHA      = 1.0d-3 + ( 8.5d-4 ) * LAI_DEPTH
         CL         = ( 1.42d0 ) * EXP( -( 3.0d-1 ) * LAI_DEPTH )

         C_P_SUN    = ALPHA * CL * Q_SUN / 
     &                SQRT( 1.d0 + ALPHA*ALPHA * Q_SUN*Q_SUN )

         C_P_SHADE  = ALPHA * CL * Q_SHADE / 
     &                SQRT( 1.d0 + ALPHA*ALPHA * Q_SHADE*Q_SHADE )

         ! Update C_PPFD_I at layer I
         C_PPFD_I   = F_SUN * C_P_SUN + F_SHADE * C_P_SHADE

         ! Add on to total C_PPFD
         C_PPFD     = C_PPFD + WEIGHTGAUSS( I ) * C_PPFD_I * LAI

      ENDDO

      ! Prevent negative values.
      GAMMA_P = MAX( C_PPFD / NORMAL_FACTOR, 0d0 )

      END FUNCTION GET_GAMMA_P
!EOC
!------------------------------------------------------------------------------
!          Harvard University Atmospheric Chemistry Modeling Group            !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: get_gamma_leaf_age
!
! !DESCRIPTION: Function GET\_GAMMA\_LEAF\_AGE computes the gamma exchange 
!  activity factor which is sensitive to leaf age (= GAMMA\_LEAF\_AGE).
!  Called from GET\_EMISOP\_MEGAN, GET\_EMMBO\_MEGAN, and GET\_EMMONOG\_MEGAN.
!\\
!\\
! !INTERFACE:
!
      FUNCTION GET_GAMMA_LEAF_AGE( CMLAI, PMLAI, T, SPECIES, TT ) 
     &            RESULT( GAMMA_LEAF_AGE )
!
! !INPUT PARAMETERS: 
!
      REAL*8,           INTENT(IN) :: T        ! Number of days between 
                                               !  current and previous LAI.
      REAL*8,           INTENT(IN) :: CMLAI    ! Current month's LAI [cm2/cm2]
      REAL*8,           INTENT(IN) :: PMLAI    ! Previous months LAI [cm2/cm2]
      CHARACTER(LEN=4), INTENT(IN) :: SPECIES  ! BVOC species name
      REAL*8,           INTENT(IN) :: TT       ! Daily average temperature [K]
!
! !RETURN VALUE:
!
      REAL*8                       :: GAMMA_LEAF_AGE   ! Activity factor    
!
! !REMARKS:
!  References (see above for full citations):
!  ============================================================================
!  (3 ) Guenther et al, 2006
!  (5 ) Guenther et al, MEGAN user mannual 2007-08
! 
! !REVISION HISTORY: 
!  (1 ) Original code by Dorian Abbot (9/2003). Modified for the standard 
!        code by May Fu (11/2004)
!  (2 ) Update to publically released (as of 11/2004) MEGAN algorithm and 
!        modified for the standard code by May Fu (11/2004).
!  (3 ) Algorithm is based on the latest User's Guide (tmf, 11/19/04)
!  (4 ) Renamed & now includes specific relative emission activity factors for
!       each BVOC based on MEGAN v2.1 algorithm (mpb,2008)
!  (5 ) Now calculate TI (number of days after budbreak required to induce 
!       iso. em.) and TM (number of days after budbreak required to reach 
!       peak iso. em. rates) using the daily average temperature, instead 
!       of using fixed values (mpb,2008)
!       NOTE: Can create 20% increases in tropics (Guenther et al 2006)
!  (6 ) Implemented change for the calculation of FGRO if ( CMLAI > PMLAI ),
!       i.e. if LAI has increased with time, and used new values for 
!       all foilage fractions if ( CMLAI = PMLAI ). Also removed TG variable 
!       as not now needed. (mpb,2000)
!  17 Dec 2009 - R. Yantosca - Added ProTeX headers
!EOP
!------------------------------------------------------------------------------
!BOC
!
! !LOCAL VARIABLES:
!
      ! M_AGE: leaf age factor
      REAL*8             :: M_AGE

      ! FNEW, ANEW: new foliage that emits negligible amounts of isoprene
      REAL*8             :: FNEW

      ! FGRO, AGRO: growing foliage that emits isoprene at low rates
      REAL*8             :: FGRO

      ! FMAT, AMAT: mature foliage that emits isoprene at peak rates
      REAL*8             :: FMAT

      ! FSEN, ASEN: senescing foliage that emits isoprene at reduced rates
      REAL*8             :: FSEN

      ! TI: number of days after budbreak required to induce iso. em.
      REAL*8             :: TI   

      ! TM: number of days after budbreak required to reach peak iso. em. rates
      REAL*8             :: TM

      ! Index for the relative emission activity (mpb,2008)
      INTEGER            :: AINDX
 
      ! Use species specific relative emission activity factors (mpb,2008)
      INTEGER, PARAMETER :: N_CAT = 4
      REAL*8             :: ANEW(N_CAT)
      REAL*8             :: AGRO(N_CAT)
      REAL*8             :: AMAT(N_CAT)
      REAL*8             :: ASEN(N_CAT)
      REAL*8             :: NORM_V(N_CAT)

      ! Constant Factors (not used)
      DATA    ANEW(  1),  AGRO(  1),  AMAT(  1),  ASEN(  1)
     &     /  1.0d0    ,  1.0d0    ,  1.0d0    ,  1.0d0      /
      ! Monoterpenes 
      DATA    ANEW(  2),  AGRO(  2),  AMAT(  2),  ASEN(  2)
     &     /  2.0d0   ,   1.8d0    ,  0.95d0   ,  1.0d0      /
      ! Isoprene and MBO 
      DATA    ANEW(  3),  AGRO(  3),  AMAT(  3),  ASEN(  3)
     &     /  0.05d0   ,  0.6d0    ,  1.125d0  ,  1.0d0      /
      ! Current set-up (v7-04-11) - used for other VOCs (OVOC)
      DATA    ANEW(  4),  AGRO(  4),  AMAT(  4),  ASEN(  4)
     &     /  0.01d0   ,  0.5d0    ,  1.00d0   ,  0.33d0     /

      ! Normalization factors
      DATA   NORM_V(1) , NORM_V(2) , NORM_V(3) , NORM_V(4) 
     &     /                 1.0d0 , ! Constant
     &       0.96153846153846145d0 , ! Monoterpenes
     &       0.94339622641509424d0 , ! Isoprene & MBO
     &         1.132502831257078d0 / ! Other VOCs

      !=================================================================
      ! GET_GAMMA_LEAF_AGE begins here!
      !================================================================= 
      
      !-----------------------
      ! Compute TI and TM 
      ! (mpb,2009)
      !-----------------------

      IF ( TT <= 303.d0 ) THEN
         TI = 5.0d0 + 0.7 * ( 300.0d0 - TT )
      ELSEIF ( TT >  303.d0 ) THEN
         TI = 2.9d0
      ENDIF   
      TM = 2.3d0 * TI

      !-----------------------
      ! Compute M_AGE
      !-----------------------

      IF ( CMLAI == PMLAI ) THEN !(i.e. LAI stays the same) 

         !New values           Old Vlaues (mpb, 2009)
         FMAT = 0.8d0            !1.d0  
         FNEW = 0.d0             !0.d0
         FGRO = 0.1d0            !0.d0
         FSEN = 0.1d0            !0.d0

      ELSE IF ( CMLAI > PMLAI ) THEN !(i.e. LAI has INcreased) 

         IF ( T > TI ) THEN
            FNEW = ( TI / T ) * ( 1.d0 -  PMLAI / CMLAI )
         ELSE
            FNEW = 1.d0 - ( PMLAI / CMLAI )
         ENDIF

         IF ( T > TM ) THEN
            FMAT = ( PMLAI / CMLAI ) +
     &             ( ( T - TM ) / T ) * ( 1.d0 -  PMLAI / CMLAI )
         ELSE 
            FMAT = ( PMLAI / CMLAI )
         ENDIF

         ! Implement new condition for FGRO (mpb,2009)
         FSEN = 0.d0
         FGRO = 1.d0 - FNEW - FMAT

      ELSE ! This is the case if  PMLAI > CMLAI (i.e. LAI has DEcreased) 

         FSEN = ( PMLAI - CMLAI ) / PMLAI
         FMAT = 1.d0 - FSEN
         FGRO = 0.d0
         FNEW = 0.d0

      ENDIF

      ! Choose relative emission activity (mpb,2009)
      SELECT CASE ( TRIM(SPECIES) )
      CASE ('CONSTANT')
         AINDX = 1
      CASE ('MONO')
         AINDX = 2
      CASE ( 'ISOP','MBOT' )
         AINDX = 3
      CASE ('OVOC')
         AINDX = 4
      CASE DEFAULT
           CALL ERROR_STOP( 'Invalid BVOC species', 
     &                      'GET_GAMMA_LEAF_AGE (megan_mod.f)' )
      END SELECT

      ! Age factor
      M_AGE = FNEW*ANEW(AINDX) + FGRO*AGRO(AINDX) + 
     &        FMAT*AMAT(AINDX) + FSEN*ASEN(AINDX)  

      !Note: I think this should be normalized.
      !But, in the megan code I've consistently download 
      !from NCAR it never is...

      ! Normalize & prevent negative values
      GAMMA_LEAF_AGE = MAX( M_AGE * NORM_V(AINDX) , 0d0 )

      END FUNCTION GET_GAMMA_LEAF_AGE
!EOC
!------------------------------------------------------------------------------
!          Harvard University Atmospheric Chemistry Modeling Group            !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: get_gamma_lai
!
! !DESCRIPTION: Function GET\_GAMMA\_LAI computes the gamma exchange activity 
!  factor which is sensitive to leaf area (= GAMMA\_LAI).  Called from
!  GET\_EMISOP\_MEGAN, GET\_EMMBO\_MEGAN, and GET\_EMMONOG\_MEGAN.
!\\
!\\
! !INTERFACE:
!
      FUNCTION GET_GAMMA_LAI( CMLAI ) RESULT( GAMMA_LAI )
!
! !INPUT PARAMETERS: 
!
      REAL*8, INTENT(IN)  :: CMLAI       ! Current month's LAI [cm2/cm2]
!
! !RETURN VALUE:
!
      REAL*8              :: GAMMA_LAI 
!
! !REMARKS:
!  References (see above for full citations):
!  ============================================================================
!  (1 ) Guenther et al, 2006
!  (2 ) Guenther et al, MEGAN user mannual 2007-08
! 
! !REVISION HISTORY: 
!  (1 ) Original code by Dorian Abbot (9/2003).  Modified for the standard 
!        code by May Fu (11/2004)
!  (2 ) Update to publically released (as of 11/2004) MEGAN algorithm and 
!        modified for the standard code by May Fu (11/2004).
!  (3 ) Algorithm is based on the latest MEGAN v2.1 User's Guide (mpb,2009)
!  17 Dec 2009 - R. Yantosca - Added ProTeX headers
!EOP
!------------------------------------------------------------------------------
!BOC

      !-----------------------
      ! Compute GAMMA_LAI
      !-----------------------
      GAMMA_LAI = 0.49d0 * CMLAI / SQRT( 1.d0 + 0.2d0 * CMLAI*CMLAI )

      END FUNCTION GET_GAMMA_LAI 
!EOC
!------------------------------------------------------------------------------
!          Harvard University Atmospheric Chemistry Modeling Group            !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: get_aef
!
! !DESCRIPTION: Subroutine GET\_AEF reads Annual Emission Factor for all
!  biogenic VOC species from disk.  Called from GET\_AEF is called from 
!  "main.f".
!\\
!\\
! !INTERFACE:
!
      SUBROUTINE GET_AEF
!
! !USES:
!
      ! References to F90 modules
      USE BPCH2_MOD,      ONLY : GET_RES_EXT, READ_BPCH2
      USE DIRECTORY_MOD,  ONLY : DATA_DIR_1x1
      USE REGRID_1x1_MOD, ONLY : DO_REGRID_1x1
      USE TIME_MOD,       ONLY : GET_TS_EMIS
      USE GRID_MOD,       ONLY : GET_AREA_M2
!
! !REMARKS:
!  Reference: (5 ) Guenther et al, 2004 
! 
! !REVISION HISTORY: 
!  (1 ) Original code by Dorian Abbot (9/2003).  Modified for the standard 
!        code by May Fu (11/2004)
!  (2 ) AEF detailed in the latest MEGAN User's Guide (tmf, 11/19/04)
!  (3 ) Bug fix (tmf, 11/30/04)
!  (4 ) Now reads 1x1 files and regrids to current resolution (bmy, 10/24/05)
!  (5 ) Uses new v2.1 emission factors maps for isoprene, MBO and 7 monoterpene
!        species, download in 2009. (mpb,2009)
!  17 Dec 2009 - R. Yantosca - Added ProTeX headers
!EOP
!------------------------------------------------------------------------------
!BOC
!
! !LOCAL VARIABLES:
!
      INTEGER                 :: I, J, IJLOOP
      REAL*4                  :: ARRAY(I1x1,J1x1,1)
      REAL*8                  :: DTSRCE, AREA_M2, FACTOR
      CHARACTER(LEN=255)      :: FILENAME


      ! ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      ! In MEGAN v2.1 the emission factors are expressed in units of:
      !
      ! ** micro-grams of compound per m2 per hour **
      !
      ! Previously this was:
      !
      ! ** micro-grams of CARBON per m2 per hour **    
      !
      ! We must therefore apply a conversion factor to change the new 
      ! 'compound' emissions into carbon emissions.
      REAL*8                  ::  ISOP2CARBON               
      REAL*8                  ::  MONO2CARBON
      REAL*8                  ::  MBO2CARBON
      !
      ! Note, where it is written as [ug C/m2/hr] think of C = compound
      ! (mpb,2008)
      ! ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

      !=================================================================
      ! GET_AEF begins here!
      !=================================================================

      ! Emission timestep [min]
      DTSRCE = GET_TS_EMIS()

      !-----------------------------------------------
      ! Determine the 'carbon conversion' factors
      ! = molar mass carbon / molar mass compound
      ! (mpb,2008)
      !-----------------------------------------------

      ISOP2CARBON =  60d0 /  68d0
      MONO2CARBON = 120d0 / 136d0
      MBO2CARBON  =  60d0 /  86d0
      
      !---------------------------------------------
      ! Read in ISOPRENE Annual Emission Factors
      !---------------------------------------------

      ! 1x1 file name
      FILENAME = TRIM( DATA_DIR_1x1 ) //
     &   'MEGAN_200909/MEGANv2.1_AEF_ISOPRENE.geos.1x1'

      ! Echo info
      WRITE( 6, 100 ) TRIM( FILENAME )
100   FORMAT( '     - GET_AEF: Reading ', a )

      ! Read data at 1x1 resolution [ug C/m2/hr] 
      CALL READ_BPCH2( FILENAME, 'BIOGSRCE', 99,   
     &                 0d0,       I1x1,      J1x1,     
     &                 1,         ARRAY,     QUIET=.TRUE. )

      ! Regrid from 1x1 to the current grid (also cast to REAL*8)
      CALL DO_REGRID_1x1( 'ug C/m2/hr', ARRAY, AEF_ISOP ) 

      ! Loop over longitudes
      DO J = 1, JJPAR
       
         ! Grid box surface area [m2]
         AREA_M2 = GET_AREA_M2( J )

         ! Conversion factor from [ug C/m2/hr] to [kg C/box]
         FACTOR = 1.d-9 / 3600.d0 * AREA_M2 * DTSRCE * 60.d0
         
 
         ! Loop over latitudes
         DO I = 1, IIPAR

            ! Convert AEF_ISOP To [kg C/box]
            AEF_ISOP(I,J) = AEF_ISOP(I,J) * FACTOR * ISOP2CARBON

         ENDDO
      ENDDO

      !---------------------------------------------
      ! Read in MONOTERPENE Annual Emission Factors
      !---------------------------------------------

      ! 1x1 file name
      FILENAME = TRIM( DATA_DIR_1x1 ) //
     &  TRIM( MEGAN_SUBDIR ) // 'MEGANv2.1_AEF_MONOTERPENES.geos.1x1'

      ! Echo info
      WRITE( 6, 100 ) TRIM( FILENAME )

      ! Read data at 1x1 resolution [ug C/m2/hr]
      CALL READ_BPCH2( FILENAME, 'BIOGSRCE', 99,   
     &                 0d0,       I1x1,      J1x1,     
     &                 1,         ARRAY,     QUIET=.TRUE. )

      ! Regrid from 1x1 to the current grid (also cast to REAL*8)
      CALL DO_REGRID_1x1( 'ug C/m2/hr', ARRAY, AEF_MONOT ) 

      ! Loop over longitudes
      DO J = 1, JJPAR

         ! Surface area 
         AREA_M2 = GET_AREA_M2( J )

         ! Conversion factor from [ug C/m2/hr] to [kg C/box]
         FACTOR  = 1.d-9 / 3600.d0 * AREA_M2 * DTSRCE * 60.d0

         ! Loop over latitudes
         DO I = 1, IIPAR

            ! Convert AEF_MONOT to [kg C/box]
            AEF_MONOT(I,J) = AEF_MONOT(I,J) * FACTOR * MONO2CARBON

         ENDDO
      ENDDO

      !---------------------------------------------
      ! Read in MBO Annual Emission Factors
      !---------------------------------------------

      ! 1x1 file name
      FILENAME = TRIM( DATA_DIR_1x1 ) //
     &    TRIM( MEGAN_SUBDIR ) // 'MEGANv2.1_AEF_MBO.geos.1x1'

      ! Echo info
      WRITE( 6, 100 ) TRIM( FILENAME )

      ! Read data at 1x1 resolution [ug C/m2/hr]
      CALL READ_BPCH2( FILENAME, 'BIOGSRCE', 99,   
     &                 0d0,       I1x1,      J1x1,     
     &                 1,         ARRAY,     QUIET=.TRUE. )

      ! Regrid from 1x1 to the current grid (also cast to REAL*8)
      CALL DO_REGRID_1x1( 'ug C/m2/hr', ARRAY, AEF_MBO ) 

      ! Loop over latitudes
      DO J = 1, JJPAR

         ! Grid box surface area
         AREA_M2 = GET_AREA_M2( J )

         ! Conversion factor from [ug C/m2/hr] to [kg C/box]
         FACTOR = 1.d-9 / 3600.d0 * AREA_M2 * DTSRCE * 60.d0

         ! Loop over longitudes
         DO I = 1, IIPAR

            ! Convert AEF to [kg C/box/step]
            AEF_MBO(I,J) = AEF_MBO(I,J) * FACTOR * MBO2CARBON
            
         ENDDO
      ENDDO

      !---------------------------------------------
      ! Read in other VOC Annual Emission Factors
      !---------------------------------------------

      ! 1x1 file name
      FILENAME = TRIM( DATA_DIR_1x1 ) //
     &           'MEGAN_200510/MEGAN_AEF_MTP.geos.1x1' 

      ! Echo info
      WRITE( 6, 100 ) TRIM( FILENAME )

      ! Read data at 1x1 resolution [ug C/m2/hr]
      CALL READ_BPCH2( FILENAME, 'BIOGSRCE', 99,   
     &                 0d0,       I1x1,      J1x1,     
     &                 1,         ARRAY,     QUIET=.TRUE. )

      ! Regrid from 1x1 to the current grid (also cast to REAL*8)
      CALL DO_REGRID_1x1( 'ug C/m2/hr', ARRAY, AEF_OVOC ) 

      ! Loop over latitudes
      DO J = 1, JJPAR

         ! Grid box surface area
         AREA_M2 = GET_AREA_M2( J )

         ! Conversion factor from [ug C/m2/hr] to [kg C/box]
         FACTOR = 1.d-9 / 3600.d0 * AREA_M2 * DTSRCE * 60.d0

         ! Loop over longitudes
         DO I = 1, IIPAR

            ! Convert AEF to [kg C/box/step]
            AEF_OVOC(I,J) = AEF_OVOC(I,J) * FACTOR
            
         ENDDO
      ENDDO

      !--------------------------------------------------
      ! Read in other Monoterpene Annual Emission Factors
      !-------------------------------------------------

      ! 1) Alpha Pinene (APIN) 

      ! 1x1 file name
      FILENAME = TRIM( DATA_DIR_1x1 ) //
     &   TRIM( MEGAN_SUBDIR ) // 'MEGANv2.1_AEF_ALPHA_PINENE.geos.1x1' 

      ! Echo info
      WRITE( 6, 100 ) TRIM( FILENAME )

      ! Read data at 1x1 resolution [ug C/m2/hr]
      CALL READ_BPCH2( FILENAME, 'BIOGSRCE', 99,   
     &                 0d0,       I1x1,      J1x1,     
     &                 1,         ARRAY,     QUIET=.TRUE. )

      ! Regrid from 1x1 to the current grid (also cast to REAL*8)
      CALL DO_REGRID_1x1( 'ug C/m2/hr', ARRAY, AEF_APINE ) 

      ! Loop over latitudes
      DO J = 1, JJPAR

         ! Grid box surface area
         AREA_M2 = GET_AREA_M2( J )

         ! Conversion factor from [ug C/m2/hr] to [kg C/box]
         FACTOR = 1.d-9 / 3600.d0 * AREA_M2 * DTSRCE * 60.d0

         ! Loop over longitudes
         DO I = 1, IIPAR

            ! Convert AEF to [kg C/box/step]
            AEF_APINE(I,J) = AEF_APINE(I,J) * FACTOR * MONO2CARBON
            
         ENDDO
      ENDDO

      ! 2) Beta Pinene (BPIN) 

      ! 1x1 file name
      FILENAME = TRIM( DATA_DIR_1x1 ) //
     &     TRIM( MEGAN_SUBDIR ) // 'MEGANv2.1_AEF_BETA_PINENE.geos.1x1' 

      ! Echo info
      WRITE( 6, 100 ) TRIM( FILENAME )

      ! Read data at 1x1 resolution [ug C/m2/hr]
      CALL READ_BPCH2( FILENAME, 'BIOGSRCE', 99,   
     &                 0d0,       I1x1,      J1x1,     
     &                 1,         ARRAY,     QUIET=.TRUE. )

      ! Regrid from 1x1 to the current grid (also cast to REAL*8)
      CALL DO_REGRID_1x1( 'ug C/m2/hr', ARRAY, AEF_BPINE ) 

      ! Loop over latitudes
      DO J = 1, JJPAR

         ! Grid box surface area
         AREA_M2 = GET_AREA_M2( J )

         ! Conversion factor from [ug C/m2/hr] to [kg C/box]
         FACTOR = 1.d-9 / 3600.d0 * AREA_M2 * DTSRCE * 60.d0

         ! Loop over longitudes
         DO I = 1, IIPAR

            ! Convert AEF to [kg C/box/step]
            AEF_BPINE(I,J) = AEF_BPINE(I,J) * FACTOR * MONO2CARBON
            
         ENDDO
      ENDDO

      ! 3) Limonene (LIMON) 

      ! 1x1 file name
      FILENAME = TRIM( DATA_DIR_1x1 ) //
     &   TRIM( MEGAN_SUBDIR ) // 'MEGANv2.1_AEF_LIMONENE.geos.1x1' 

      ! Echo info
      WRITE( 6, 100 ) TRIM( FILENAME )

      ! Read data at 1x1 resolution [ug C/m2/hr]
      CALL READ_BPCH2( FILENAME, 'BIOGSRCE', 99,   
     &                 0d0,       I1x1,      J1x1,     
     &                 1,         ARRAY,     QUIET=.TRUE. )

      ! Regrid from 1x1 to the current grid (also cast to REAL*8)
      CALL DO_REGRID_1x1( 'ug C/m2/hr', ARRAY, AEF_LIMON ) 

      ! Loop over latitudes
      DO J = 1, JJPAR

         ! Grid box surface area
         AREA_M2 = GET_AREA_M2( J )

         ! Conversion factor from [ug C/m2/hr] to [kg C/box]
         FACTOR = 1.d-9 / 3600.d0 * AREA_M2 * DTSRCE * 60.d0

         ! Loop over longitudes
         DO I = 1, IIPAR

            ! Convert AEF to [kg C/box/step]
            AEF_LIMON(I,J) = AEF_LIMON(I,J) * FACTOR * MONO2CARBON
            
         ENDDO
      ENDDO

      ! 4) Sabinene (SABIN) 

      ! 1x1 file name
      FILENAME = TRIM( DATA_DIR_1x1 ) //
     &   TRIM( MEGAN_SUBDIR ) // 'MEGANv2.1_AEF_SABINENE.geos.1x1' 

      ! Echo info
      WRITE( 6, 100 ) TRIM( FILENAME )

      ! Read data at 1x1 resolution [ug C/m2/hr]
      CALL READ_BPCH2( FILENAME, 'BIOGSRCE', 99,   
     &                 0d0,       I1x1,      J1x1,     
     &                 1,         ARRAY,     QUIET=.TRUE. )

      ! Regrid from 1x1 to the current grid (also cast to REAL*8)
      CALL DO_REGRID_1x1( 'ug C/m2/hr', ARRAY, AEF_SABIN ) 

      ! Loop over latitudes
      DO J = 1, JJPAR

         ! Grid box surface area
         AREA_M2 = GET_AREA_M2( J )

         ! Conversion factor from [ug C/m2/hr] to [kg C/box]
         FACTOR = 1.d-9 / 3600.d0 * AREA_M2 * DTSRCE * 60.d0

         ! Loop over longitudes
         DO I = 1, IIPAR

            ! Convert AEF to [kg C/box/step]
            AEF_SABIN(I,J) = AEF_SABIN(I,J) * FACTOR * MONO2CARBON
            
         ENDDO
      ENDDO

      ! 5) Myrcene (MYRCN) 

      ! 1x1 file name
      FILENAME = TRIM( DATA_DIR_1x1 ) //
     &   TRIM( MEGAN_SUBDIR ) // 'MEGANv2.1_AEF_MYRCENE.geos.1x1' 

      ! Echo info
      WRITE( 6, 100 ) TRIM( FILENAME )

      ! Read data at 1x1 resolution [ug C/m2/hr]
      CALL READ_BPCH2( FILENAME, 'BIOGSRCE', 99,   
     &                 0d0,       I1x1,      J1x1,     
     &                 1,         ARRAY,     QUIET=.TRUE. )

      ! Regrid from 1x1 to the current grid (also cast to REAL*8)
      CALL DO_REGRID_1x1( 'ug C/m2/hr', ARRAY, AEF_MYRCN ) 

      ! Loop over latitudes
      DO J = 1, JJPAR

         ! Grid box surface area
         AREA_M2 = GET_AREA_M2( J )

         ! Conversion factor from [ug C/m2/hr] to [kg C/box]
         FACTOR = 1.d-9 / 3600.d0 * AREA_M2 * DTSRCE * 60.d0

         ! Loop over longitudes
         DO I = 1, IIPAR

            ! Convert AEF to [kg C/box/step]
            AEF_MYRCN(I,J) = AEF_MYRCN(I,J) * FACTOR * MONO2CARBON
            
         ENDDO
      ENDDO

      ! 6) 3-Carene (CAREN) 

      ! 1x1 file name
      FILENAME = TRIM( DATA_DIR_1x1 ) //
     &   TRIM( MEGAN_SUBDIR ) // 'MEGANv2.1_AEF_CARENE.geos.1x1' 

      ! Echo info
      WRITE( 6, 100 ) TRIM( FILENAME )

      ! Read data at 1x1 resolution [ug C/m2/hr]
      CALL READ_BPCH2( FILENAME, 'BIOGSRCE', 99,   
     &                 0d0,       I1x1,      J1x1,     
     &                 1,         ARRAY,     QUIET=.TRUE. )

      ! Regrid from 1x1 to the current grid (also cast to REAL*8)
      CALL DO_REGRID_1x1( 'ug C/m2/hr', ARRAY, AEF_CAREN ) 

      ! Loop over latitudes
      DO J = 1, JJPAR

         ! Grid box surface area
         AREA_M2 = GET_AREA_M2( J )

         ! Conversion factor from [ug C/m2/hr] to [kg C/box]
         FACTOR = 1.d-9 / 3600.d0 * AREA_M2 * DTSRCE * 60.d0

         ! Loop over longitudes
         DO I = 1, IIPAR

            ! Convert AEF to [kg C/box/step]
            AEF_CAREN(I,J) = AEF_CAREN(I,J) * FACTOR * MONO2CARBON
            
         ENDDO
      ENDDO

      ! 7) Ocimene (OCIMN) 

      ! 1x1 file name
      FILENAME = TRIM( DATA_DIR_1x1 ) //
     &   TRIM( MEGAN_SUBDIR ) // 'MEGANv2.1_AEF_OCIMENE.geos.1x1' 

      ! Echo info
      WRITE( 6, 100 ) TRIM( FILENAME )

      ! Read data at 1x1 resolution [ug C/m2/hr]
      CALL READ_BPCH2( FILENAME, 'BIOGSRCE', 99,   
     &                 0d0,       I1x1,      J1x1,     
     &                 1,         ARRAY,     QUIET=.TRUE. )

      ! Regrid from 1x1 to the current grid (also cast to REAL*8)
      CALL DO_REGRID_1x1( 'ug C/m2/hr', ARRAY, AEF_OCIMN ) 

      ! Loop over latitudes
      DO J = 1, JJPAR

         ! Grid box surface area
         AREA_M2 = GET_AREA_M2( J )

         ! Conversion factor from [ug C/m2/hr] to [kg C/box]
         FACTOR = 1.d-9 / 3600.d0 * AREA_M2 * DTSRCE * 60.d0

         ! Loop over longitudes
         DO I = 1, IIPAR

            ! Convert AEF to [kg C/box/step]
            AEF_OCIMN(I,J) = AEF_OCIMN(I,J) * FACTOR * MONO2CARBON
            
         ENDDO
      ENDDO

      END SUBROUTINE GET_AEF
!EOC
!------------------------------------------------------------------------------
!          Harvard University Atmospheric Chemistry Modeling Group            !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: get_aef_05x0666
!
! !DESCRIPTION: Subroutine GET\_AEF\_05x0666 reads Annual Emission Factor for 
!  all biogenic VOC species from disk.  Called from "main.f".  Specially
!  constructed to read 0.5 x 0.666 nested grid data for the GEOS-5 nested
!  grid simulations.
!\\
!\\
! !INTERFACE:
!
      SUBROUTINE GET_AEF_05x0666
!
! !USES:
!
      USE BPCH2_MOD,      ONLY : GET_RES_EXT, READ_BPCH2
      USE DIRECTORY_MOD,  ONLY : DATA_DIR_1x1
      USE REGRID_1x1_MOD, ONLY : DO_REGRID_1x1
      USE REGRID_1x1_MOD, ONLY : DO_REGRID_05x0666
      USE TIME_MOD,       ONLY : GET_TS_EMIS
      USE GRID_MOD,       ONLY : GET_AREA_M2
      USE DIRECTORY_MOD,  ONLY : DATA_DIR
!
! !REMARKS:
!  Reference: (5 ) Guenther et al, 2004 
! 
! !REVISION HISTORY: 
!  (1) Specially constructed to read 0.5 x 0.666 nested grid data for the 
!      GEOS-5 nested grid simulations. (yxw, dan, bmy, 11/6/08)
!  17 Dec 2009 - R. Yantosca - Added ProTeX headers
!EOP
!------------------------------------------------------------------------------
!BOC
!
! !LOCAL VARIABLES:
!
      INTEGER                 :: I, J, IJLOOP
      REAL*4                  :: ARRAY(I05x0666,J05x0666,1)
      REAL*8                  :: GEOS_05x0666(I05x0666,J05x0666,1)  !(dan)
      REAL*8                  :: DTSRCE, AREA_M2, FACTOR
      CHARACTER(LEN=255)      :: FILENAME

      !=================================================================
      ! GET_AEF begins here!
      !=================================================================

      ! Emission timestep [min]
      DTSRCE = GET_TS_EMIS()

      !---------------------------------------------
      ! Read in ISOPRENE Annual Emission Factors
      !---------------------------------------------

      ! 1x1 file name
      FILENAME = TRIM( DATA_DIR ) //
     &           'MEGAN_200510/MEGAN_AEF_ISOP.geos.05x0666'

      ! Echo info
      WRITE( 6, 100 ) TRIM( FILENAME )
100   FORMAT( '     - GET_AEF: Reading ', a )

      ! Read data at 1x1 resolution [ug C/m2/hr] 
      CALL READ_BPCH2( FILENAME, 'BIOGSRCE', 99,
     &                 0d0,       I05x0666,      J05x0666,
     &                 1,         ARRAY,     QUIET=.TRUE. )

         ! Cast to REAL*8 before regridding
         GEOS_05x0666(:,:,1) = ARRAY(:,:,1)

      ! Regrid from 1x1 to the current grid (also cast to REAL*8)
      CALL DO_REGRID_05x0666( 1, 'ug C/m2/hr', GEOS_05x0666, AEF_ISOP )

      ! Loop over longitudes
      DO J = 1, JJPAR

         ! Grid box surface area [m2]
         AREA_M2 = GET_AREA_M2( J )

         ! Conversion factor from [ug C/m2/hr] to [kg C/box]
         FACTOR = 1.d-9 / 3600.d0 * AREA_M2 * DTSRCE * 60.d0

         ! Loop over latitudes
         DO I = 1, IIPAR

            ! Convert AEF_ISOP To [kg C/box]
            AEF_ISOP(I,J) = AEF_ISOP(I,J) * FACTOR

         ENDDO
      ENDDO

      !---------------------------------------------
      ! Read in MONOTERPENE Annual Emission Factors
      !---------------------------------------------

      ! 1x1 file name
      FILENAME = TRIM( DATA_DIR ) //
     &           'MEGAN_200510/MEGAN_AEF_MTP.geos.05x0666'

      ! Echo info
      WRITE( 6, 100 ) TRIM( FILENAME )

      ! Read data at 1x1 resolution [ug C/m2/hr]
      CALL READ_BPCH2( FILENAME, 'BIOGSRCE', 99,
     &                 0d0,       I05x0666,      J05x0666,
     &                 1,         ARRAY,     QUIET=.TRUE. )

         ! Cast to REAL*8 before regridding
         GEOS_05x0666(:,:,1) = ARRAY(:,:,1)

      ! Regrid from 1x1 to the current grid (also cast to REAL*8)
      CALL DO_REGRID_05x0666( 1,'ug C/m2/hr', GEOS_05x0666, AEF_MONOT )

      ! Loop over longitudes
      DO J = 1, JJPAR

         ! Surface area 
         AREA_M2 = GET_AREA_M2( J )

         ! Conversion factor from [ug C/m2/hr] to [kg C/box]
         FACTOR  = 1.d-9 / 3600.d0 * AREA_M2 * DTSRCE * 60.d0

         ! Loop over latitudes
         DO I = 1, IIPAR

            ! Convert AEF_MONOT to [kg C/box]
            AEF_MONOT(I,J) = AEF_MONOT(I,J) * FACTOR

         ENDDO
      ENDDO

      !---------------------------------------------
      ! Read in MBO Annual Emission Factors
      !---------------------------------------------

      ! 1x1 file name
      FILENAME = TRIM( DATA_DIR ) //
     &           'MEGAN_200510/MEGAN_AEF_MBO.geos.05x0666'

      ! Echo info
      WRITE( 6, 100 ) TRIM( FILENAME )

      ! Read data at 1x1 resolution [ug C/m2/hr]
      CALL READ_BPCH2( FILENAME, 'BIOGSRCE', 99,
     &                 0d0,       I05x0666,      J05x0666,
     &                 1,         ARRAY,     QUIET=.TRUE. )

      ! Cast to REAL*8 before regridding
      GEOS_05x0666(:,:,1) = ARRAY(:,:,1)


      ! Regrid from 1x1 to the current grid (also cast to REAL*8)
      CALL DO_REGRID_05x0666( 1,'ug C/m2/hr',GEOS_05x0666, AEF_MBO )

      ! Loop over latitudes
      DO J = 1, JJPAR

         ! Grid box surface area
         AREA_M2 = GET_AREA_M2( J )

         ! Conversion factor from [ug C/m2/hr] to [kg C/box]
         FACTOR = 1.d-9 / 3600.d0 * AREA_M2 * DTSRCE * 60.d0

         ! Loop over longitudes
         DO I = 1, IIPAR

            ! Convert AEF to [kg C/box/step]
            AEF_MBO(I,J) = AEF_MBO(I,J) * FACTOR

         ENDDO
      ENDDO

      !---------------------------------------------
      ! Read in other VOC Annual Emission Factors
      !---------------------------------------------

      ! 1x1 file name
      FILENAME = TRIM( DATA_DIR ) //
     &           'MEGAN_200510/MEGAN_AEF_MTP.geos.05x0666'

      ! Echo info
      WRITE( 6, 100 ) TRIM( FILENAME )

      ! Read data at 1x1 resolution [ug C/m2/hr]
      CALL READ_BPCH2( FILENAME, 'BIOGSRCE', 99,
     &                 0d0,       I05x0666,      J05x0666,
     &                 1,         ARRAY,     QUIET=.TRUE. )

      ! Cast to REAL*8 before regridding
      GEOS_05x0666(:,:,1) = ARRAY(:,:,1)

      ! Regrid from 1x1 to the current grid (also cast to REAL*8)
      CALL DO_REGRID_05x0666( 1,'ug C/m2/hr', GEOS_05x0666, AEF_OVOC )

      ! Loop over latitudes
      DO J = 1, JJPAR

         ! Grid box surface area
         AREA_M2 = GET_AREA_M2( J )

         ! Conversion factor from [ug C/m2/hr] to [kg C/box]
         FACTOR = 1.d-9 / 3600.d0 * AREA_M2 * DTSRCE * 60.d0

         ! Loop over longitudes
         DO I = 1, IIPAR

            ! Convert AEF to [kg C/box/step]
            AEF_OVOC(I,J) = AEF_OVOC(I,J) * FACTOR

         ENDDO
      ENDDO

      END SUBROUTINE GET_AEF_05x0666
!EOC
!------------------------------------------------------------------------------
!          Harvard University Atmospheric Chemistry Modeling Group            !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: update_t_day
!
! !DESCRIPTION: Subroutine UPDATE\_T\_DAY must be called every time the 
!  A-3 fields are updated. Each 3h TS value for each gridbox is moved up one 
!  spot in the matrix and the current value is put in the last spot.
!\\
!\\
! !INTERFACE:
!
      SUBROUTINE UPDATE_T_DAY
!
! !USES:
!
      USE MEGANUT_MOD     ! We use all functions from the module
! 
! !REVISION HISTORY: 
!  (1 ) All MEGAN biogenic emission are currently calculated using TS from DAO 
!        met field. TS is the surface air temperature, which should be 
!        carefully distinguished from TSKIN. (tmf, 11/20/04)
!  (2 ) In GEOS4, TS are originally T2M in the A3 files, read in 
!        'a3_read_mod.f'. 
!  17 Dec 2009 - R. Yantosca - Added ProTeX headers
!EOP
!------------------------------------------------------------------------------
!BOC
!
! !LOCAL VARIABLES:
!
      INTEGER           :: I, J, D

!--- Moved all functions to module MEGANUT_MOD
!      ! External functions
!      REAL*8, EXTERNAL  :: XLTMMP
!      REAL*8, EXTERNAL  :: XLPARDR ! (mpb,2009)
!      REAL*8, EXTERNAL  :: XLPARDF ! (mpb,2009)

      !=================================================================
      ! UPDATE_T_DAY begins here!
      !=================================================================
!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I, J, D )
      DO J = 1, JJPAR
      DO I = 1, IIPAR

         ! Move each day up
         DO D = DAY_DIM, 2, -1
            ! Need PAR as well as Temp  (mpb,2009)
            T_DAY(I,J,D)     = T_DAY(I,J,D-1)
            PARDR_DAY(I,J,D) = PARDR_DAY(I,J,D-1)
            PARDF_DAY(I,J,D) = PARDF_DAY(I,J,D-1)
         ENDDO
            
         ! Store 
         T_DAY(I,J,1)     = XLTMMP(I,J)
         PARDF_DAY(I,J,1) = XLPARDF(I,J)
         PARDR_DAY(I,J,1) = XLPARDR(I,J)

      ENDDO
      ENDDO
!$OMP END PARALLEL DO
          
      END SUBROUTINE UPDATE_T_DAY
!EOC
!------------------------------------------------------------------------------
!          Harvard University Atmospheric Chemistry Modeling Group            !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: update_t_15_avg
!
! !DESCRIPTION: Subroutine UPDATE\_T\_15\_AVG should be called at the 
!  beginning of each day. It loops through the gridboxes doing the following:
!
!  \begin{enumerate}
!  \item Average T\_DAY over the 8 TS values during the day.  
!  \item Push the daily average TS values through T\_15, throwing out the 
!        oldest and putting the newest (the T\_DAY average) in the last spot 
!  \item Get T\_15\_AVG by averaging T\_15 over the 15 day period. 
!  \end{enumerate}
!
! !INTERFACE:
!
      SUBROUTINE UPDATE_T_15_AVG
!
! !USES:
!
      IMPLICIT NONE
! 
! !REVISION HISTORY: 
!  01 Oct 1995 - M. Prather  - Initial version
!  (1 ) All MEGAN biogenic emission are currently calculated using TS from DAO 
!        met field. TS is the surface air temperature, which should be 
!        carefully distinguished from TSKIN. (tmf, 11/20/04)
!  (2 ) In GEOS4, TS are originally T2M in the A3 files, read in 
!        'a3_read_mod.f'. 
!  17 Dec 2009 - R. Yantosca - Added ProTeX headers
!EOP
!------------------------------------------------------------------------------
!BOC
!
! !LOCAL VARIABLES:
!
      INTEGER           :: I,     J,      D
      REAL*8            :: D_DIM, D_DAYS, TMP_T
      REAL*8            :: TMP_PARDR , TMP_PARDF ! (mpb,2009)

      !=================================================================
      ! UPDATE_T_15_AVG begins here!
      !=================================================================

      ! Convert to REAL*8
      D_DIM  = DBLE( DAY_DIM  )
      D_DAYS = DBLE( NUM_DAYS )

      ! Loop over grid boxes
!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I, J, D, TMP_T, TMP_PARDR, TMP_PARDF )
      DO J = 1, JJPAR
      DO I = 1, IIPAR

         ! Average T_DAY over the 8 TS values during the day.
         TMP_T = SUM( T_DAY(I,J,:) ) / D_DIM
         
         ! Do the same for light (mpb,2009)
         TMP_PARDR = SUM( PARDR_DAY(I,J,:) ) / D_DIM
         TMP_PARDF = SUM( PARDF_DAY(I,J,:) ) / D_DIM

         ! Push the daily average TS values through T_15,
         ! throwing out the oldest 
         DO D = NUM_DAYS, 2, -1
            T_15(I,J,D)     = T_15(I,J,D-1)
            PARDR_15(I,J,D) = PARDR_15(I,J,D-1)
            PARDF_15(I,J,D) = PARDF_15(I,J,D-1)
         ENDDO

         ! Put the newest daily average TS value in the first spot
         T_15(I,J,1) = TMP_T

         ! Get T_15_AVG by averaging T_15 over the 15 day period.
         T_15_AVG(I,J) = SUM( T_15(I,J,:) ) / D_DAYS 

         ! Assign daily average temperature to T_DAILY (mpb,2009)
         T_DAILY(I,J)  = TMP_T

         ! Repeat for PAR diffuse & direct (mpb,2009)
         PARDR_15(I,J,1)   = TMP_PARDR
         PARDR_15_AVG(I,J) = SUM( PARDR_15(I,J,:) ) / D_DAYS 
         PARDR_DAILY(I,J)  = TMP_PARDR

         PARDF_15(I,J,1)   = TMP_PARDF
         PARDF_15_AVG(I,J) = SUM( PARDF_15(I,J,:) ) / D_DAYS 
         PARDF_DAILY(I,J)  = TMP_PARDF


      ENDDO
      ENDDO
!$OMP END PARALLEL DO

      END SUBROUTINE UPDATE_T_15_AVG
!EOC
!------------------------------------------------------------------------------
!          Harvard University Atmospheric Chemistry Modeling Group            !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: init_megan
!
! !DESCRIPTION: Subroutine INIT\_MEGAN allocates and initializes all
!  module arrays.
!\\
!\\
! !INTERFACE:
!
      SUBROUTINE INIT_MEGAN
!
! !USES:
!
      USE A3_READ_MOD
      USE MERRA_A1_MOD
      USE FILE_MOD,    ONLY : IU_A3
      USE JULDAY_MOD,  ONLY : CALDATE
      USE ERROR_MOD,   ONLY : ALLOC_ERR
      USE LAI_MOD,     ONLY : INIT_LAI
      USE LOGICAL_MOD, ONLY : LUNZIP
      USE TIME_MOD,    ONLY : GET_FIRST_A3_TIME, GET_JD
      USE TIME_MOD,    ONLY : ITS_A_LEAPYEAR,    YMD_EXTRACT
! 
! !REVISION HISTORY: 
!  (1 ) Change the logic in the #if block for G4AHEAD. (bmy, 12/6/05)
!  (2 ) Bug fix: skip Feb 29th if GCAP (phs, 9/18/07)
!  (3 ) Now call GET_AEF_05x0666 for GEOS-5 nested grids (yxw,dan,bmy, 11/6/08)
!  17 Dec 2009 - R. Yantosca - Added ProTeX headers
!  26 Aug 2010 - R. Yantosca - Now reference merra_a1_mod.f
!  01 Sep 2010 - R. Yantosca - Now read in NUM_DAYS of sfc temp data (this had
!                              been hardwired to 15 days previously)
!  07 Feb 2011 - R. Yantosca - Fix typos: make sure to zero out the proper 
!                              PARDF_* and PARDR_* arrays after allocation
!EOP
!------------------------------------------------------------------------------
!BOC
!
! !LOCAL VARIABLES:
!
      LOGICAL              :: GCAP_LEAP
      INTEGER              :: AS
      INTEGER              :: DATE_T15b(2)
      INTEGER              :: NYMD_T15b, NHMS_T15b, NYMD_T15, NHMS_T15
      INTEGER              :: I,         J,         G4AHEAD
      INTEGER              :: THISYEAR,  THISMONTH, THISDAY, BACK_ONE
      REAL*8               :: JD_T15b,   JD_T15
      
      !=================================================================
      ! INIT_MEGAN begins here!
      !=================================================================

      ! Allocate arrays
      ALLOCATE( T_DAY( IIPAR, JJPAR, DAY_DIM ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'T_DAY' )
      T_DAY = 0d0

      ALLOCATE( T_15( IIPAR, JJPAR, NUM_DAYS ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'T_15' )
      T_15 = 0d0

      ALLOCATE( T_15_AVG( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'T_15_AVG' )
      T_15_AVG = 0d0

      ! Daily averaged temperature (mpb,2009)
      ALLOCATE( T_DAILY( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'T_DAILY' )
      T_DAILY = 0d0

      ALLOCATE( AEF_ISOP( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'AEF_ISOP' )
      AEF_ISOP = 0d0

      ALLOCATE( AEF_MONOT( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'AEF_MONOT' )
      AEF_MONOT = 0d0

      ALLOCATE( AEF_MBO( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'AEF_MBO' )
      AEF_MBO = 0d0

      ALLOCATE( AEF_OVOC( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'AEF_OVOC' )
      AEF_OVOC = 0d0

      ! New monoterpene species (mpb,2008)

      ALLOCATE( AEF_APINE( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'AEF_APINE' )
      AEF_APINE = 0d0

      ALLOCATE( AEF_BPINE( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'AEF_BPINE' )
      AEF_BPINE = 0d0

      ALLOCATE( AEF_LIMON( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'AEF_LIMON' )
      AEF_LIMON = 0d0

      ALLOCATE( AEF_SABIN( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'AEF_SABIN' )
      AEF_SABIN = 0d0

      ALLOCATE( AEF_MYRCN( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'AEF_MYRCN' )
      AEF_MYRCN = 0d0

      ALLOCATE( AEF_CAREN( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'AEF_CAREN' )
      AEF_CAREN = 0d0

      ALLOCATE( AEF_OCIMN( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'AEF_OCIMN' )
      AEF_OCIMN = 0d0

      ! AEF_SPARE no longer "global" to module (hotp 3/10/10)
      !ALLOCATE( AEF_SPARE( IIPAR, JJPAR ), STAT=AS )
      !IF ( AS /= 0 ) CALL ALLOC_ERR( 'AEF_SPARE' )
      !AEF_SPARE = 0d0

      ! Allocate arrays for light (mpb,2009)
!------------------------------------------------------------------------------
! Prior to 2/7/11:
! Fix typos: make sure to zero out the proper arrays (dbm, bmy, 2/7/11)
!      ! -- Direct --
!      ALLOCATE( PARDR_DAY( IIPAR, JJPAR, DAY_DIM ), STAT=AS )
!      IF ( AS /= 0 ) CALL ALLOC_ERR( 'PARDR_DAY' )
!      T_DAY = 0d0
!
!      ALLOCATE( PARDR_15( IIPAR, JJPAR, NUM_DAYS ), STAT=AS )
!      IF ( AS /= 0 ) CALL ALLOC_ERR( 'PARDR_15' )
!      T_15 = 0d0
!
!      ALLOCATE( PARDR_15_AVG( IIPAR, JJPAR ), STAT=AS )
!      IF ( AS /= 0 ) CALL ALLOC_ERR( 'PARDR_15_AVG' )
!      T_15_AVG = 0d0
!
!      ALLOCATE( PARDR_DAILY( IIPAR, JJPAR ), STAT=AS )
!      IF ( AS /= 0 ) CALL ALLOC_ERR( 'PARDR_DAILY' )
!      T_DAILY = 0d0
!
!      ! -- Diffuse --
!      ALLOCATE( PARDF_DAY( IIPAR, JJPAR, DAY_DIM ), STAT=AS )
!      IF ( AS /= 0 ) CALL ALLOC_ERR( 'PARDF_DAY' )
!      T_DAY = 0d0
!
!      ALLOCATE( PARDF_15( IIPAR, JJPAR, NUM_DAYS ), STAT=AS )
!      IF ( AS /= 0 ) CALL ALLOC_ERR( 'PARDF_15' )
!      T_15 = 0d0
!
!      ALLOCATE( PARDF_15_AVG( IIPAR, JJPAR ), STAT=AS )
!      IF ( AS /= 0 ) CALL ALLOC_ERR( 'PARDF_15_AVG' )
!      T_15_AVG = 0d0
!
!      ALLOCATE( PARDF_DAILY( IIPAR, JJPAR ), STAT=AS )
!      IF ( AS /= 0 ) CALL ALLOC_ERR( 'PARDF_DAILY' )
!      T_DAILY = 0d0
!------------------------------------------------------------------------------

      ! -- Direct --
      ALLOCATE( PARDR_DAY( IIPAR, JJPAR, DAY_DIM ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'PARDR_DAY' )
      PARDR_DAY = 0d0

      ALLOCATE( PARDR_15( IIPAR, JJPAR, NUM_DAYS ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'PARDR_15' )
      PARDR_15 = 0d0

      ALLOCATE( PARDR_15_AVG( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'PARDR_15_AVG' )
      PARDR_15_AVG = 0d0

      ALLOCATE( PARDR_DAILY( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'PARDR_DAILY' )
      PARDR_DAILY = 0d0

      ! -- Diffuse --
      ALLOCATE( PARDF_DAY( IIPAR, JJPAR, DAY_DIM ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'PARDF_DAY' )
      PARDF_DAY = 0d0

      ALLOCATE( PARDF_15( IIPAR, JJPAR, NUM_DAYS ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'PARDF_15' )
      PARDF_15 = 0d0

      ALLOCATE( PARDF_15_AVG( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'PARDF_15_AVG' )
      PARDF_15_AVG = 0d0

      ALLOCATE( PARDF_DAILY( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'PARDF_DAILY' )
      PARDF_DAILY = 0d0

      ! Get annual emission factors for MEGAN inventory
#if   defined( GRID05x0666 )
      CALL GET_AEF_05x0666     ! GEOS-5 nested grids only
#else
      CALL GET_AEF             ! Global simulations
#endif 

      ! Initialize LAI arrays
      CALL INIT_LAI

      !=================================================================
      ! Read A3 fields for the 15 days before the start of the run
      ! This section has been added so that the previous 15 day temp.
      ! average can be calculated for biogenic emissions.  Do only if 
      ! MEGAN biogenic emissions must be calculated.  
      !=================================================================

      ! Get the first time for reading A-3 files
      DATE_T15b = GET_FIRST_A3_TIME()
      NYMD_T15b = DATE_T15b(1)
      NHMS_T15b = DATE_T15b(2)

      ! Astronomical Julian Date of the A3 file at start of run
      JD_T15b   = GET_JD( NYMD_T15b, NHMS_T15b )

#if   defined( GEOS_3 )

      ! For GEOS-1, GEOS-STRAT, GEOS-3, the A-3 fields are timestamped 
      ! by ending time: 00Z, 03Z, 06Z, 09Z, 12Z, 15Z, 18Z, 21Z.  
      G4AHEAD   = 0

#elif defined( MERRA )

      ! For MERRA, the A1 fields are timestamped on the half-hours:
      ! 00:30, 01:30, 02:30, ... 23:30
      G4AHEAD   = 003000

#else

      ! For GEOS4, the A-3 fields are timestamped by the center of 
      ! the 3-hr period: 01:30Z, 04:30Z, 07:30Z, 10:30Z, 
      ! 13:30Z, 16:30Z, 19:30Z, 22:30Z
      G4AHEAD   = 013000

#endif
      
      !------------------------------------------------------
      ! GCAP: Need to test if it's leap year (phs, 9/18/07)
      !------------------------------------------------------

      ! Initialize
      THISDAY   = 0
      GCAP_LEAP = .FALSE.
      BACK_ONE  = 0

#if   defined( GCAP )

      ! Extract year, month, day from NYMD_T15b
      CALL YMD_EXTRACT( NYMD_T15b, THISYEAR, THISMONTH, THISDAY )

      ! If it's a leap year then set appropriate variables
      IF ( ITS_A_LEAPYEAR( THISYEAR, FORCE=.TRUE. )  .AND.
     &     THISMONTH == 3                            .AND.
     &     THISDAY   <  16  ) THEN 
         GCAP_LEAP = .TRUE.
         BACK_ONE  = 1
      ENDIF

#endif

      ! Remove any leftover A-3 files in temp dir (if necessary)
      IF ( LUNZIP ) THEN
         CALL UNZIP_A3_FIELDS( 'remove all' )
      ENDIF

      ! Loop over 15 days
      !------------------------------------------------------------------
      ! Prior to 9/1/10:
      ! We now average over NUM_DAYS=10 days of data instead of 15
      ! days, so rewrite the DO loop accordingly (bmy, 9/1/10)
      !DO I = 15+BACK_ONE, 1, -1
      !------------------------------------------------------------------
      DO I = NUM_DAYS+BACK_ONE, 1, -1

         ! Skip February 29th for GCAP (phs, 9/18/07)
         IF ( GCAP_LEAP .AND. I == THISDAY ) CYCLE

         ! Julian day at start of each of the 15 days 
         JD_T15 = JD_T15b - DBLE( I ) * 1.d0

         ! Call CALDATE to compute the current YYYYMMDD and HHMMSS
         CALL CALDATE( JD_T15, NYMD_T15, NHMS_T15 )

         ! Unzip A-3 files for archving (if necessary)
         IF ( LUNZIP ) THEN
            CALL UNZIP_A3_FIELDS( 'unzip foreground', NYMD_T15 )
         ENDIF

         ! Loop over 3h periods during day
         !---------------------------------------------------------
         ! Prior to 8/20/10:
         ! Eliminate hardwiring; now use DAY_DIM (bmy, 8/20/10)
         !DO J = 0, 7
         !---------------------------------------------------------
         DO J = 0, DAY_DIM-1  

#if   defined( MERRA )

            !-----------------------------
            ! MERRA met fields
            ! Sfc temp is hourly data
            !-----------------------------

            ! Open A1 fields
            CALL OPEN_MERRA_A1_FIELDS( NYMD_T15, 010000*J + G4AHEAD )

            ! Read A1 fields from disk
            CALL GET_MERRA_A1_FIELDS(  NYMD_T15, 010000*J + G4AHEAD ) 

#else
            !-----------------------------
            ! All other met field types!
            ! Sfc temp is 3-hourly data
            !-----------------------------

            ! Open A3 fields
            CALL OPEN_A3_FIELDS( NYMD_T15, 030000*J + G4AHEAD )

            ! Read A3 fields from disk
            CALL GET_A3_FIELDS(  NYMD_T15, 030000*J + G4AHEAD ) 

#endif

            ! Update hourly temperatures
            CALL UPDATE_T_DAY
         ENDDO     

         ! Compute 15-day average temperatures
         CALL UPDATE_T_15_AVG

         ! Remove A-3 file from temp dir (if necessary)
         IF ( LUNZIP ) THEN
            CALL UNZIP_A3_FIELDS( 'remove date', NYMD_T15 )
         ENDIF

      ENDDO

      ! Close the A-3 file
      CLOSE( IU_A3 )

      ! Remove any leftover A-3 files in temp dir
      IF ( LUNZIP ) THEN
         CALL UNZIP_A3_FIELDS(  'remove all' )
      ENDIF

      END SUBROUTINE INIT_MEGAN
!EOC
!------------------------------------------------------------------------------
!          Harvard University Atmospheric Chemistry Modeling Group            !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: cleanup_megan
!
! !DESCRIPTION: Subroutine CLEANUP\_MEGAN deallocates all allocated arrays 
!  at the end of a GEOS-Chem model run.
!\\
!\\
! !INTERFACE:
!
      SUBROUTINE CLEANUP_MEGAN
! 
! !REVISION HISTORY: 
!  17 Dec 2009 - R. Yantosca - Added ProTeX headers
!EOP
!------------------------------------------------------------------------------
!BOC
      !=================================================================
      ! CLEANUP_MEGAN begins here!
      !=================================================================

      IF ( ALLOCATED( T_DAY         ) ) DEALLOCATE( T_DAY         )
      IF ( ALLOCATED( T_15          ) ) DEALLOCATE( T_15          )
      IF ( ALLOCATED( T_15_AVG      ) ) DEALLOCATE( T_15_AVG      )
      IF ( ALLOCATED( T_DAILY       ) ) DEALLOCATE( T_DAILY       )
      IF ( ALLOCATED( PARDR_DAY     ) ) DEALLOCATE( PARDR_DAY     )
      IF ( ALLOCATED( PARDR_15      ) ) DEALLOCATE( PARDR_15      )
      IF ( ALLOCATED( PARDR_15_AVG  ) ) DEALLOCATE( PARDR_15_AVG  )
      IF ( ALLOCATED( PARDR_DAILY   ) ) DEALLOCATE( PARDR_DAILY   )
      IF ( ALLOCATED( PARDF_DAY     ) ) DEALLOCATE( PARDF_DAY     )
      IF ( ALLOCATED( PARDF_15      ) ) DEALLOCATE( PARDF_15      )
      IF ( ALLOCATED( PARDF_15_AVG  ) ) DEALLOCATE( PARDF_15_AVG  )
      IF ( ALLOCATED( PARDF_DAILY   ) ) DEALLOCATE( PARDF_DAILY   )

      IF ( ALLOCATED( AEF_ISOP  ) ) DEALLOCATE( AEF_ISOP  )
      IF ( ALLOCATED( AEF_MONOT ) ) DEALLOCATE( AEF_MONOT )
      IF ( ALLOCATED( AEF_MBO   ) ) DEALLOCATE( AEF_MBO   )
      IF ( ALLOCATED( AEF_OVOC  ) ) DEALLOCATE( AEF_OVOC  )
      IF ( ALLOCATED( AEF_APINE ) ) DEALLOCATE( AEF_APINE )
      IF ( ALLOCATED( AEF_BPINE ) ) DEALLOCATE( AEF_BPINE )
      IF ( ALLOCATED( AEF_LIMON ) ) DEALLOCATE( AEF_LIMON )
      IF ( ALLOCATED( AEF_SABIN ) ) DEALLOCATE( AEF_SABIN )
      IF ( ALLOCATED( AEF_MYRCN ) ) DEALLOCATE( AEF_MYRCN )
      IF ( ALLOCATED( AEF_CAREN ) ) DEALLOCATE( AEF_CAREN )
      IF ( ALLOCATED( AEF_OCIMN ) ) DEALLOCATE( AEF_OCIMN )
      ! bug fix (hotp 3/10/10)
      !IF ( ALLOCATED( AEF_SPARE ) ) DEALLOCATE( AEF_SPARE )

      END SUBROUTINE CLEANUP_MEGAN
!EOC
      END MODULE MEGAN_MOD