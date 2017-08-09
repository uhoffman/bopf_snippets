      DATA: ls_uibb_instance_key          TYPE fpm_s_uibb_instance_key.

      ls_uibb_instance_key-component = 'FPM_LIST_UIBB'.
      ls_uibb_instance_key-config_id = '/MOC/L_ISS_OBJECT_REF'.

      DATA(lo_fpm) = cl_fpm_factory=>get_instance( ).

      DATA(lv_mode) = lo_fpm->get_uibb_edit_mode(
         is_uibb_instance_key = ls_uibb_instance_key
         iv_window_name       = 'LIST_WINDOW' ).
         
      IF lv_mode EQ if_fpm_constants=>gc_edit_mode-read_only.
      
      ENDIF.
