! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
! 
! Sparse Hessian Data Structures File
! 
! Generated by KPP-2.2 symbolic chemistry Kinetics PreProcessor
!       (http://www.cs.vt.edu/~asandu/Software/KPP)
! KPP is distributed under GPL, the general public licence
!       (http://www.gnu.org/copyleft/gpl.html)
! (C) 1995-1997, V. Damian & A. Sandu, CGRER, Univ. Iowa
! (C) 1997-2005, A. Sandu, Michigan Tech, Virginia Tech
!     With important contributions from:
!        M. Damian, Villanova University, USA
!        R. Sander, Max-Planck Institute for Chemistry, Mainz, Germany
! 
! File                 : gckpp_HessianSP.f90
! Time                 : Wed Sep 15 16:00:44 2010
! Working directory    : /mnt/lstr04/srv/home/c/ccarouge/KPP/geoschem_kppfiles/v8-03-02/SOA
! Equation file        : gckpp.kpp
! Output root filename : gckpp
! 
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



MODULE gckpp_HessianSP

  PUBLIC
  SAVE


! Hessian Sparse Data
! 

  INTEGER, PARAMETER, DIMENSION(360) :: IHESS_I_0 = (/ &
      12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 21, 21, &
      21, 23, 24, 25, 26, 27, 28, 29, 29, 29, 30, 30, &
      30, 31, 31, 31, 32, 32, 32, 33, 33, 33, 34, 35, &
      35, 36, 36, 37, 37, 38, 39, 39, 40, 40, 41, 41, &
      42, 42, 43, 43, 44, 44, 45, 45, 46, 46, 47, 47, &
      48, 48, 49, 49, 50, 50, 51, 51, 52, 52, 53, 53, &
      54, 54, 55, 55, 56, 56, 56, 56, 57, 57, 57, 58, &
      58, 58, 59, 59, 59, 60, 60, 60, 60, 60, 60, 60, &
      60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 61, 61, &
      61, 61, 62, 62, 62, 62, 62, 62, 62, 62, 63, 63, &
      63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 64, 64, &
      64, 64, 65, 65, 65, 65, 65, 65, 65, 65, 65, 66, &
      66, 66, 66, 66, 66, 66, 66, 66, 67, 67, 67, 67, &
      67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, &
      67, 67, 67, 67, 68, 68, 68, 68, 68, 69, 69, 69, &
      69, 69, 70, 70, 70, 70, 70, 70, 71, 71, 71, 71, &
      71, 71, 71, 71, 71, 72, 72, 72, 72, 72, 72, 73, &
      73, 73, 73, 73, 73, 74, 74, 74, 74, 74, 75, 75, &
      75, 75, 75, 75, 76, 76, 76, 76, 76, 76, 77, 77, &
      77, 77, 77, 77, 77, 77, 77, 77, 77, 77, 77, 77, &
      77, 78, 78, 78, 78, 78, 78, 79, 79, 79, 79, 79, &
      79, 80, 80, 80, 80, 80, 81, 81, 81, 81, 81, 81, &
      81, 81, 81, 81, 81, 81, 81, 81, 81, 81, 81, 81, &
      81, 81, 81, 81, 81, 81, 81, 81, 81, 82, 82, 82, &
      82, 82, 82, 82, 82, 82, 82, 82, 82, 82, 82, 82, &
      82, 82, 82, 82, 82, 82, 82, 82, 82, 82, 82, 82, &
      82, 82, 82, 82, 82, 82, 82, 82, 82, 82, 82, 82, &
      82, 82, 82, 82, 82, 82, 82, 82, 82, 82, 82, 82, &
      82, 82, 82, 82, 82, 82, 82, 82, 82, 82, 82, 82, &
      82, 82, 82, 82, 82, 83, 83, 83, 83, 83, 83, 84 /)
  INTEGER, PARAMETER, DIMENSION(360) :: IHESS_I_1 = (/ &
      84, 84, 84, 84, 84, 84, 84, 84, 84, 84, 84, 84, &
      84, 84, 84, 84, 84, 84, 84, 84, 84, 84, 84, 84, &
      85, 85, 85, 85, 85, 85, 85, 85, 85, 85, 86, 86, &
      86, 86, 86, 87, 87, 87, 87, 87, 87, 87, 87, 87, &
      87, 87, 87, 87, 87, 88, 88, 88, 88, 88, 88, 88, &
      88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, &
      88, 88, 88, 89, 89, 89, 89, 89, 89, 89, 89, 89, &
      89, 89, 89, 89, 89, 89, 89, 89, 90, 90, 90, 90, &
      90, 90, 90, 90, 91, 91, 91, 91, 91, 91, 91, 91, &
      91, 91, 92, 92, 92, 92, 92, 92, 93, 93, 93, 93, &
      93, 93, 93, 93, 93, 94, 94, 94, 94, 94, 94, 94, &
      95, 95, 95, 95, 95, 95, 95, 95, 95, 95, 95, 95, &
      95, 95, 95, 95, 95, 95, 95, 95, 95, 95, 95, 95, &
      95, 95, 95, 95, 95, 95, 95, 95, 95, 95, 95, 95, &
      95, 95, 95, 95, 95, 95, 95, 95, 95, 95, 95, 95, &
      95, 95, 95, 95, 95, 95, 95, 95, 95, 96, 96, 96, &
      96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, &
      96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, &
      96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, &
      96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, &
      96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, &
      96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, &
      96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, &
      96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, &
      96, 96, 96, 96, 97, 97, 97, 97, 97, 97, 97, 97, &
      97, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, &
      98, 98, 98, 98, 98, 99, 99, 99, 99, 99, 99, 99, &
      99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, &
      99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, &
      99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99 /)
  INTEGER, PARAMETER, DIMENSION(161) :: IHESS_I_2 = (/ &
      99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,100, &
     100,100,100,100,100,100,100,100,100,100,100,100, &
     100,100,100,100,100,101,101,101,101,101,101,101, &
     101,101,101,101,101,101,101,101,101,101,101,101, &
     101,101,101,101,101,101,101,101,101,101,101,101, &
     101,101,101,101,101,101,101,101,101,101,102,102, &
     102,102,102,102,102,102,102,102,102,102,102,102, &
     102,102,102,102,102,102,102,102,102,102,102,102, &
     102,102,102,102,102,102,102,102,102,102,102,102, &
     102,102,102,102,102,102,102,102,102,102,102,102, &
     102,102,102,102,102,102,102,102,102,102,103,103, &
     103,103,103,103,103,103,103,103,103,103,103,103, &
     103,103,103,103,103,103,103,103,103,103,103,103, &
     103,103,103,103,103 /)
  INTEGER, PARAMETER, DIMENSION(881) :: IHESS_I = (/&
    IHESS_I_0, IHESS_I_1, IHESS_I_2 /)

  INTEGER, PARAMETER, DIMENSION(360) :: IHESS_J_0 = (/ &
      30, 44, 59, 31, 31, 32, 32, 33, 33, 59, 60, 91, &
     101, 23, 24, 25, 26, 90, 94, 29, 96,102, 30, 44, &
      44, 25, 31, 31, 23, 32, 32, 24, 33, 33, 99, 35, &
      35, 36, 36, 37,102, 99, 39, 95, 40, 85, 41, 65, &
      42, 66, 43, 90, 44, 44, 45, 96, 46, 87, 47, 94, &
      48, 96, 49, 96, 50, 83, 51, 76, 52, 78, 53, 72, &
      54, 79, 55, 75, 56, 64, 69, 80, 57, 70, 92, 58, &
      58, 97, 59, 59, 59, 59, 60, 61, 63, 71, 72, 72, &
      79, 79, 79, 82, 82, 84, 88, 88, 91, 93, 59, 61, &
      61, 61, 42, 62, 66, 66, 66, 85, 85, 85, 63, 64, &
      71, 75, 75, 75, 79, 79, 79, 80, 80, 80, 64, 64, &
      64, 64, 26, 41, 65, 65, 65, 65, 85, 85, 85, 26, &
      42, 66, 66, 66, 66, 85, 85, 85, 35, 36, 44, 64, &
      67, 70, 72, 75, 78, 78, 78, 79, 80, 81, 82, 84, &
      88, 89, 91, 99, 68, 68, 68, 68, 86, 69, 69, 69, &
      69, 91, 70, 70, 70, 70, 92, 92, 57, 70, 70, 70, &
      71, 71, 92, 92, 92, 53, 72, 72, 72, 72, 91, 73, &
      73, 73, 73, 89, 89, 62, 74, 74, 74, 74, 55, 75, &
      75, 75, 75, 93, 51, 61, 76, 76, 76, 76, 58, 71, &
      72, 72, 72, 74, 77, 79, 79, 79, 80, 80, 80, 83, &
      83, 52, 59, 78, 78, 78, 78, 54, 71, 79, 79, 79, &
      79, 56, 80, 80, 80, 80, 40, 41, 55, 56, 64, 64, &
      65, 65, 65, 68, 68, 68, 69, 69, 76, 76, 78, 78, &
      80, 80, 81, 81, 83, 83, 85, 85, 85, 39, 44, 44, &
      48, 58, 58, 59, 61, 64, 64, 64, 65, 66, 68, 68, &
      68, 69, 69, 69, 70, 70, 70, 71, 72, 72, 72, 73, &
      74, 74, 74, 75, 75, 75, 76, 76, 76, 78, 78, 78, &
      79, 79, 79, 80, 82, 82, 83, 83, 83, 84, 85, 87, &
      90, 91, 92, 92, 92, 93, 94, 94, 94, 94, 95, 95, &
      95, 95, 95, 97, 97, 50, 61, 83, 83, 83, 83, 43 /)
  INTEGER, PARAMETER, DIMENSION(360) :: IHESS_J_1 = (/ &
      46, 61, 68, 68, 68, 73, 73, 73, 76, 76, 76, 83, &
      83, 83, 84, 84, 85, 85, 85, 87, 87, 87, 87, 93, &
      35, 35, 40, 68, 68, 68, 85, 85, 85, 85, 68, 73, &
      74, 85, 86, 36, 36, 46, 85, 85, 85, 87, 87, 87, &
      87, 87, 90, 90, 90, 64, 64, 64, 69, 69, 69, 71, &
      72, 73, 74, 74, 75, 75, 75, 77, 79, 79, 79, 88, &
      88, 91, 93, 70, 70, 72, 73, 73, 74, 75, 75, 79, &
      79, 85, 85, 85, 89, 89, 92, 92, 43, 81, 81, 90, &
      90, 90, 90, 90, 59, 78, 78, 78, 91, 91, 91, 92, &
      92, 92, 57, 59, 92, 92, 92, 92, 59, 78, 78, 78, &
      92, 92, 92, 93, 93, 47, 63, 94, 94, 94, 94, 94, &
      39, 44, 44, 61, 64, 64, 65, 65, 66, 66, 68, 68, &
      69, 69, 70, 70, 72, 72, 73, 73, 73, 74, 74, 74, &
      75, 75, 76, 76, 78, 78, 79, 79, 80, 80, 83, 83, &
      85, 85, 85, 87, 87, 90, 90, 92, 92, 94, 94, 95, &
      95, 95, 95, 95, 95, 96, 97,101,101, 29, 30, 31, &
      32, 33, 58, 58, 59, 60, 61, 63, 64, 64, 64, 64, &
      65, 65, 65, 65, 66, 66, 66, 66, 68, 68, 69, 69, &
      70, 70, 70, 70, 71, 72, 72, 72, 72, 73, 73, 74, &
      74, 74, 75, 75, 75, 75, 76, 76, 77, 78, 78, 78, &
      78, 79, 79, 79, 79, 80, 80, 80, 82, 82, 83, 83, &
      83, 83, 84, 85, 85, 85, 85, 87, 87, 87, 87, 87, &
      90, 90, 91, 92, 92, 92, 92, 93, 94, 94, 94, 94, &
      95, 95, 95, 95, 95, 95, 96, 96, 96, 96, 96, 96, &
      96, 96, 98,100, 45, 71, 91, 91, 95, 96, 97, 97, &
      97, 58, 59, 61, 71, 90, 91, 93, 94, 95, 96, 96, &
      96, 98, 98, 98,102, 37, 49, 56, 58, 58, 64, 64, &
      64, 65, 66, 68, 68, 68, 69, 69, 69, 70, 72, 73, &
      74, 75, 76, 76, 76, 78, 78, 78, 79, 80, 80, 80, &
      83, 85, 87, 90, 90, 92, 94, 94, 95, 96, 96, 96 /)
  INTEGER, PARAMETER, DIMENSION(161) :: IHESS_J_2 = (/ &
      97, 97, 98, 98, 99, 99, 99,100,100,100,101, 35, &
      36, 44, 59, 61, 67, 81, 82, 84, 88, 89, 91, 96, &
      98, 99,100,100,100, 48, 64, 64, 64, 65, 66, 68, &
      69, 70, 72, 73, 73, 73, 74, 74, 74, 74, 75, 75, &
      75, 76, 78, 79, 80, 83, 84, 84, 85, 87, 88, 88, &
      90, 92, 94, 95, 95, 96, 97, 99,101,101, 23, 24, &
      25, 26, 29, 30, 35, 36, 37, 39, 40, 41, 42, 43, &
      44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, &
      56, 57, 58, 59, 59, 60, 61, 61, 62, 63, 67, 71, &
      71, 77, 81, 82, 84, 86, 88, 89, 91, 91, 93, 93, &
      96, 96, 96, 96, 96, 98, 99,100,102,102, 31, 32, &
      33, 64, 65, 66, 68, 69, 70, 72, 73, 74, 75, 76, &
      78, 79, 80, 83, 85, 87, 90, 92, 94, 95, 96, 97, &
      98, 99,100,101,102 /)
  INTEGER, PARAMETER, DIMENSION(881) :: IHESS_J = (/&
    IHESS_J_0, IHESS_J_1, IHESS_J_2 /)

  INTEGER, PARAMETER, DIMENSION(360) :: IHESS_K_0 = (/ &
     102,102,102, 96,103, 96,103, 96,103, 98,102, 98, &
     103,102,102,102,102, 99, 99,102, 96,102,102,100, &
     102,102, 96,103,102, 96,103,102, 96,103,101,100, &
     102,100,102,102,103,100,102, 96,102, 96,102, 96, &
     102, 96,102, 96,100,102,102, 97,102, 96,102, 96, &
     102,101,102, 99,102, 96,102, 96,102, 96,102, 96, &
     102, 96,102, 96,102, 96, 96, 96,102, 96, 96, 98, &
     102, 99, 98,100,102, 98,102, 98,102, 98, 95,101, &
      95,101,103,100,102,102,100,102, 98, 98, 98, 98, &
     100,102,102,102, 95,101,103, 95,101,103,102,103, &
      98, 95,101,103, 95,101,103, 95,101,103, 95, 96, &
     101,103,102,102, 95, 96,101,103, 95,101,103,102, &
     102, 95, 96,101,103, 95,101,103,100,100,100,103, &
     102,103,103,103, 95,101,103,103,103,100,100,100, &
     100,100,100,102, 95, 96,101,103,102, 95, 96,101, &
     103,100, 95, 96,101,103, 95,101,102, 95,101,103, &
      98,102, 95,101,103,102, 95, 96,101,103,102, 95, &
      96,101,103,100,102,102, 95, 96,101,103,102, 95, &
      96,101,103,102,102,100, 95, 96,101,103,102, 98, &
      95,101,103, 95,102, 95,101,103, 95,101,103, 95, &
     101,102,100, 95, 96,101,103,102,102, 95, 96,101, &
     103,102, 95, 96,101,103,102,102,102,102, 95,101, &
      95,101,103, 95,101,103, 95,101, 95,101, 95,101, &
      95,101,100,102, 95,101, 95,101,103,102,100,102, &
     102, 98,102, 98, 98, 95,101,103, 95, 95, 95,101, &
     103, 95,101,103, 95,101,103, 98, 95,101,103, 95, &
      95,101,103, 95,101,103, 95,101,103, 95,101,103, &
      95,101,103, 95,100,102, 95,101,103,102, 95, 95, &
      95, 98, 95,101,103, 98, 95, 96,101,103, 95, 97, &
      98,101,103,101,103,102,102, 95, 96,101,103,102 /)
  INTEGER, PARAMETER, DIMENSION(360) :: IHESS_K_1 = (/ &
     102, 98, 95,101,103, 95,101,103, 95,101,103, 95, &
     101,103,100,102, 95,101,103, 87, 95,101,103, 98, &
     100,102,102, 95,101,103, 95, 96,101,103, 96,103, &
     103,103,102,100,102,102, 95,101,103, 87, 95, 96, &
     101,103, 95,101,103, 95,101,103, 95,101,103, 98, &
     101, 96, 95,101, 95,101,103,102, 95,101,103,100, &
     102, 98, 98, 95,101,101, 95,101,101, 95,101, 95, &
     101, 95,101,103,100,102, 95,101,102,100,102, 95, &
      96, 99,101,103, 98, 95,101,103, 98,100,102, 95, &
     101,103,102,102, 95, 96,101,103, 98, 95,101,103, &
      95,101,103, 98,102,102,102, 95, 96, 99,101,103, &
     102,100,102, 98, 95,101, 95,101, 95,101, 95,101, &
      95,101, 95,101, 95,101, 95, 96,101, 95, 96,101, &
      95,101, 95,101, 95,101, 95,101, 95,101, 95,101, &
      95,101,103, 95,101, 95,101, 95,101, 95,101, 95, &
      96, 97, 98,101,103,101,101,101,103,102,102, 96, &
      96, 96, 98,102, 98,102, 98,102, 95, 96,101,103, &
      95, 96,101,103, 95, 96,101,103, 95, 96, 95, 96, &
      95, 96,101,103,102, 95, 96,101,103, 95, 96, 95, &
      96,101, 95, 96,101,103, 95, 96,102, 95, 96,101, &
     103, 95, 96,101,103, 95, 96,103,100,102, 95, 96, &
     101,103,102, 95, 96,101,103, 87, 95, 96,101,103, &
      95, 96, 98, 95, 96,101,103, 98, 95, 96,101,103, &
      95, 96, 97, 98,101,103, 96, 97, 98, 99,100,101, &
     102,103,102,102,102,102,100,102, 97, 97, 99,101, &
     103, 98, 98, 98, 98, 96, 98, 98, 96, 98, 97, 98, &
     101, 99,102,103,102,102,102,102, 98,102, 95,101, &
     103,103,103, 95,101,103, 95,101,103,103,103,103, &
     103,103, 95,101,103, 95,101,103,103, 95,101,103, &
     103,103,103, 99,103,103, 99,103,103, 99,100,103 /)
  INTEGER, PARAMETER, DIMENSION(161) :: IHESS_K_2 = (/ &
      99,103, 99,103,100,101,102,100,102,103,103,100, &
     100,100,100,100,102,100,100,100,100,100,100,100, &
      99,100,100,102,103,102, 95,101,103,101,101,101, &
     101,101,101, 95,101,103, 95, 96,101,103, 95,101, &
     103,101,101,101,101,101,100,102,101,101,100,102, &
     101,101,101, 97,101,101,103,101,101,103,102,102, &
     102,102,102,102,102,102,102,102,102,102,102,102, &
     102,102,102,102,102,102,102,102,102,102,102,102, &
     102,102,102, 98,102,102, 98,102,102,102,102, 98, &
     102,102,102,102,102,102,102,102, 98,102, 98,102, &
      98,100,101,102,103,102,102,102,102,103,103,103, &
     103,103,103,103,103,103,103,103,103,103,103,103, &
     103,103,103,103,103,103,103,103,103,103,103,103, &
     103,100,103,103,103 /)
  INTEGER, PARAMETER, DIMENSION(881) :: IHESS_K = (/&
    IHESS_K_0, IHESS_K_1, IHESS_K_2 /)


END MODULE gckpp_HessianSP
