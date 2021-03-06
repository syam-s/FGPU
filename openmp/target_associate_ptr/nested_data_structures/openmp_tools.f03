module openmp_tools

   use iso_c_binding
   use omp_lib
   implicit none

   public :: omp_target_alloc, omp_target_free, omp_target_associate_ptr, omp_target_disassociate_ptr

   interface

      type(C_PTR) function omp_target_alloc( num_bytes, device_num ) bind ( c, name = 'omp_target_alloc' )
        use iso_c_binding
        implicit none

        integer(C_SIZE_T), value :: num_bytes
        integer(C_INT), value :: device_num
      end function omp_target_alloc

      subroutine omp_target_free( h_ptr, device_num ) bind ( c, name = 'omp_target_free' )
        use iso_c_binding
        implicit none

        type(C_PTR), value :: h_ptr
        integer(C_INT), value :: device_num
      end subroutine omp_target_free

      integer (C_INT) function omp_target_associate_ptr( h_ptr, d_ptr, num_bytes, offset, device_num)
        use iso_c_binding
        implicit none

        type(C_PTR), value :: h_ptr, d_ptr
        integer(C_SIZE_T), value :: num_bytes, offset
        integer(C_INT), value :: device_num
      end function omp_target_associate_ptr

      integer (C_INT) function omp_target_disassociate_ptr( h_ptr, device_num)
        use iso_c_binding
        implicit none

        type(C_PTR), value :: h_ptr
        integer(C_INT), value :: device_num
      end function omp_target_disassociate_ptr

   end interface

contains

   subroutine map_to_double_1d(h_ptr, use_external_device_allocator)
      use iso_c_binding
      implicit none

      real(C_DOUBLE), pointer, intent(in) :: h_ptr(:)
      logical(C_BOOL), intent(in) :: use_external_device_allocator

      integer(C_SIZE_T) :: num_bytes, offset
      integer :: err
      type(C_PTR) :: d_ptr

      if (use_external_device_allocator) then
         num_bytes = storage_size(h_ptr)/8*SIZE(h_ptr)
         offset = 0

         ! Using omp_target_alloc as a surrogate for an external memory allocation
         ! library.
         ! This code example is meant to demonstrate use cases where using an external
         ! memory library, such as the LLNL UMPIRE library, is required.
         d_ptr = omp_target_alloc(num_bytes, omp_get_default_device() )

         err = omp_target_associate_ptr( C_LOC(h_ptr), d_ptr, num_bytes, offset, omp_get_default_device() )
         if (err /= 0) then
            print *, "Target associate failed."
         endif

         ! Check that array shape information was copied to device by the
         ! target_associate_ptr call.
         !$omp target
         write(*,*) "Mapped pointer, shape on device is: ", SHAPE(h_ptr)
         !$omp end target
         
         !$omp target update to(h_ptr)
      else
         !$omp target enter data map(to:h_ptr)
      endif
      
   end subroutine map_to_double_1d


   subroutine map_exit_double_1d(h_ptr, use_external_device_allocator)
      use iso_c_binding
      implicit none
		real(C_DOUBLE), pointer, intent(in) :: h_ptr(:)
      logical(C_BOOL), intent(in) :: use_external_device_allocator

      type(C_PTR) :: d_ptr
      integer :: err

      if (use_external_device_allocator) then
         !$omp target update from(h_ptr)
         
!         !$omp target map (from:d_ptr)
!         d_ptr = C_LOC(h_ptr)
!         !$omp end target
 
         d_ptr = c_null_ptr
         !$omp target data use_device_ptr(h_ptr)
         d_ptr = C_LOC(h_ptr)
         !$omp end target data
         
         if(.NOT. C_ASSOCIATED(d_ptr) ) then
           print *, "Failed to get buffer address of pointer."
           call abort
         endif

         err = omp_target_disassociate_ptr( C_LOC(h_ptr), omp_get_default_device() )
         if (err /= 0) then
            print *, "Target disassociate on x failed."
         endif
      
         call omp_target_free( d_ptr, omp_get_default_device() )
      else
         !$omp target exit data map (from:h_ptr)
      endif

   end subroutine map_exit_double_1d

   subroutine map_to_typeS_1d(h_ptr, use_external_device_allocator)
      use iso_c_binding
      use example_types
      implicit none

      type(typeS), pointer, intent(in) :: h_ptr(:)
      logical(C_BOOL), intent(in) :: use_external_device_allocator

      integer(C_SIZE_T) :: num_bytes, offset
      integer :: err
      type(C_PTR) :: d_ptr

      if (use_external_device_allocator) then
         num_bytes = storage_size(h_ptr)/8*SIZE(h_ptr)
         offset = 0

         ! Using omp_target_alloc as a surrogate for an external memory allocation
         ! library.
         ! This code example is meant to demonstrate use cases where using an external
         ! memory library, such as the LLNL UMPIRE library, is required.
         d_ptr = omp_target_alloc(num_bytes, omp_get_default_device() )

         err = omp_target_associate_ptr( C_LOC(h_ptr), d_ptr, num_bytes, offset, omp_get_default_device() )
         if (err /= 0) then
            print *, "Target associate failed."
         endif

         ! Check that array shape information was copied to device by the
         ! target_associate_ptr call.
         !$omp target
         write(*,*) "Mapped pointer, shape on device is: ", SHAPE(h_ptr)
         !$omp end target
         
         !$omp target update to(h_ptr)
      else
         !$omp target enter data map(to:h_ptr)
      endif
      
   end subroutine map_to_typeS_1d

   subroutine map_exit_typeS_1d(h_ptr, use_external_device_allocator)
      use iso_c_binding
      use example_types
      implicit none
      type(typeS), pointer, intent(in) :: h_ptr(:)
      logical(C_BOOL), intent(in) :: use_external_device_allocator

      type(C_PTR) :: d_ptr
      integer :: err

      if (use_external_device_allocator) then
         !$omp target update from(h_ptr)
         
!         !$omp target map (from:d_ptr)
!         d_ptr = C_LOC(h_ptr)
!         !$omp end target
 
         d_ptr = c_null_ptr
         !$omp target data use_device_ptr(h_ptr)
         d_ptr = C_LOC(h_ptr)
         !$omp end target data
         
         if(.NOT. C_ASSOCIATED(d_ptr) ) then
           print *, "Failed to get buffer address of pointer."
           call abort
         endif
          
         err = omp_target_disassociate_ptr( C_LOC(h_ptr), omp_get_default_device() )
         if (err /= 0) then
            print *, "Target disassociate on x failed."
         endif
      
         call omp_target_free( d_ptr, omp_get_default_device() )
      else
         !$omp target exit data map (from:h_ptr)
      endif

   end subroutine map_exit_typeS_1d


   subroutine map_to_typeG_1d(h_ptr, use_external_device_allocator)
      use iso_c_binding
      use example_types
      implicit none

      type(typeG), pointer, intent(in) :: h_ptr(:)
      logical(C_BOOL), intent(in) :: use_external_device_allocator

      integer(C_SIZE_T) :: num_bytes, offset
      integer :: err
      type(C_PTR) :: d_ptr

      if (use_external_device_allocator) then
         num_bytes = storage_size(h_ptr)/8*SIZE(h_ptr)
         offset = 0

         ! Using omp_target_alloc as a surrogate for an external memory allocation
         ! library.
         ! This code example is meant to demonstrate use cases where using an external
         ! memory library, such as the LLNL UMPIRE library, is required.
         d_ptr = omp_target_alloc(num_bytes, omp_get_default_device() )

         err = omp_target_associate_ptr( C_LOC(h_ptr), d_ptr, num_bytes, offset, omp_get_default_device() )
         if (err /= 0) then
            print *, "Target associate failed."
         endif

         ! Check that array shape information was copied to device by the
         ! target_associate_ptr call.
         !$omp target
         write(*,*) "Mapped pointer, shape on device is: ", SHAPE(h_ptr)
         !$omp end target
         
         !$omp target update to(h_ptr)
      else
         !$omp target enter data map(to:h_ptr)
      endif
      
   end subroutine map_to_typeG_1d

   subroutine map_exit_typeG_1d(h_ptr, use_external_device_allocator)
      use iso_c_binding
      use example_types
      implicit none
      type(typeG), pointer, intent(in) :: h_ptr(:)
      logical(C_BOOL), intent(in) :: use_external_device_allocator

      type(C_PTR) :: d_ptr
      integer :: err

      if (use_external_device_allocator) then
         !$omp target update from(h_ptr)
         
!         !$omp target map (from:d_ptr)
!         d_ptr = C_LOC(h_ptr)
!         !$omp end target
 
         d_ptr = c_null_ptr
         !$omp target data use_device_ptr(h_ptr)
         d_ptr = C_LOC(h_ptr)
         !$omp end target data
         
         if(.NOT. C_ASSOCIATED(d_ptr) ) then
           print *, "Failed to get buffer address of pointer."
           call abort
         endif
         
         err = omp_target_disassociate_ptr( C_LOC(h_ptr), omp_get_default_device() )
         if (err /= 0) then
            print *, "Target disassociate on x failed."
         endif
      
         call omp_target_free( d_ptr, omp_get_default_device() )
      else
         !$omp target exit data map (from:h_ptr)
      endif

   end subroutine map_exit_typeG_1d

   subroutine map_to_typeQ(h_ptr, use_external_device_allocator)
      use iso_c_binding
      use example_types
      implicit none

      type(typeQ), pointer, intent(in) :: h_ptr
      logical(C_BOOL), intent(in) :: use_external_device_allocator

      integer(C_SIZE_T) :: num_bytes, offset
      integer :: err
      type(C_PTR) :: d_ptr

      if (use_external_device_allocator) then
         num_bytes = storage_size(h_ptr)/8
         offset = 0

         ! Using omp_target_alloc as a surrogate for an external memory allocation
         ! library.
         ! This code example is meant to demonstrate use cases where using an external
         ! memory library, such as the LLNL UMPIRE library, is required.
         d_ptr = omp_target_alloc(num_bytes, omp_get_default_device() )

         err = omp_target_associate_ptr( C_LOC(h_ptr), d_ptr, num_bytes, offset, omp_get_default_device() )
         if (err /= 0) then
            print *, "Target associate failed."
         endif

         !$omp target update to(h_ptr)
      else
         !$omp target enter data map(to:h_ptr)
      endif
      
   end subroutine map_to_typeQ

   subroutine map_exit_typeQ(h_ptr, use_external_device_allocator)
      use iso_c_binding
      use example_types
      implicit none
      type(typeQ), pointer, intent(in) :: h_ptr
      logical(C_BOOL), intent(in) :: use_external_device_allocator

      type(C_PTR) :: d_ptr
      integer :: err

      if (use_external_device_allocator) then
         !$omp target update from(h_ptr) 
 
!         !$omp target map (from:d_ptr)
!         d_ptr = C_LOC(h_ptr)
!         !$omp end target
 
         d_ptr = c_null_ptr
         !$omp target data use_device_ptr(h_ptr)
         d_ptr = C_LOC(h_ptr)
         !$omp end target data
 
         if(.NOT. C_ASSOCIATED(d_ptr) ) then
           print *, "Failed to get buffer address of pointer."
           call abort
         endif
      
         err = omp_target_disassociate_ptr( C_LOC(h_ptr), omp_get_default_device() )
         if (err /= 0) then
            print *, "Target disassociate on x failed."
         endif
      
         call omp_target_free( d_ptr, omp_get_default_device() )
      else
         !$omp target exit data map (from:h_ptr)
      endif

   end subroutine map_exit_typeQ

end module openmp_tools
