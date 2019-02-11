      DATA: ls_uibb_instance_key          TYPE fpm_s_uibb_instance_key.

      ls_uibb_instance_key-component = 'FPM_LIST_UIBB'.
      ls_uibb_instance_key-config_id = '[CONFIG_ID]'.

      DATA(lo_fpm) = cl_fpm_factory=>get_instance( ).

      DATA(lv_mode) = lo_fpm->get_uibb_edit_mode(
         is_uibb_instance_key = ls_uibb_instance_key
         iv_window_name       = 'LIST_WINDOW' ).
         
      IF lv_mode EQ if_fpm_constants=>gc_edit_mode-read_only.
      
      ENDIF.
      
        CONSTANTS lc_scope TYPE c VALUE '1'. "Scope: See settings of BO /IAM/ISSUE: "Lock Behavior"

  CALL FUNCTION 'ENQUEUE_/BOBF/E_LIB_1'
    EXPORTING
      mode_/bobf/s_lib_enqueue_node = 'E'    "Request exclusive lock
      mandt                         = sy-mandt
      bo_name                       = /iam/if_i_issue_c=>sc_bo_name
      key                           = iv_key
      x_bo_name                     = abap_true "' '
      x_key                         = abap_true "' '
      _scope                        = lc_scope
      _wait                         = abap_false "' '
      _collect                      = abap_false "' '
    EXCEPTIONS
      foreign_lock                  = 1
      system_failure                = 2
      OTHERS                        = 3.
  IF sy-subrc <> 0.
    MOVE /iam/cl_fpm_wiring_model_uibb=>gc_display TO cv_processing_mode.
    RETURN.
  ENDIF.
  CALL FUNCTION 'DEQUEUE_/BOBF/E_LIB_1'
    EXPORTING
      mode_/bobf/s_lib_enqueue_node = 'E'
      mandt                         = sy-mandt
      bo_name                       = /iam/if_i_issue_c=>sc_bo_name
      key                           = iv_key
      x_bo_name                     = abap_true "' '
      x_key                         = abap_true "' '
      _scope                        = lc_scope.
