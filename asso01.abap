    DATA lr_root            TYPE REF TO /iam/s_act_root.
    DATA lt_root            TYPE /iam/t_act_root.
    DATA lo_message         LIKE eo_message.
    DATA lt_key             LIKE it_key.
    DATA lt_failed_key      LIKE et_failed_key.
    DATA lv_failed          TYPE boole_d.                  " Note 1877074
    DATA lv_set_main_responsible    TYPE boole_d.   " Note 1877074
    DATA ls_failed_key              LIKE LINE OF et_failed_key. " Note 1877074

*---- Enhanced
    DATA lt_filtered_attributes   TYPE          /bobf/t_frw_name.
    DATA lr_param                 TYPE REF TO   /iam/s_a_desc_assoc_param.
    DATA lt_desc_key              TYPE /bobf/t_frw_key.
    DATA lt_desc                  TYPE /iam/t_act_desc.
    DATA lt_desc_text TYPE /iam/t_act_desctxt.
    DATA lt_hist_desc_text        LIKE lt_desc_text.
    DATA ls_msg                   TYPE symsg.
    DATA lo_msg                   TYPE REF TO /bobf/cl_frw_message.
*---- /Enhanced

    FIELD-SYMBOLS <ls_key>    LIKE LINE OF it_key.
    FIELD-SYMBOLS <ls_root>   LIKE LINE OF lt_root. " Note 1877074

    CLEAR: eo_message, et_failed_key.

*---- Enhanced (check whether a reason text was entered when rejecting task)
    IF is_ctx-act_key EQ /iam/if_act_activity_c=>sc_action-root-reject.
      CREATE DATA lr_param.
      lr_param->desc_type = 'NOTES'.
      APPEND /iam/if_act_activity_c=>sc_node_attribute-description-desc_type TO lt_filtered_attributes.
      "Get history
      io_read->retrieve_by_association( EXPORTING iv_node  = /iam/if_act_activity_c=>sc_node-root
                                                  it_key                  = it_key
                                                  iv_association          = /iam/if_act_activity_c=>sc_association-root-description_by_desc_type
                                                  is_parameters           = lr_param
                                                  it_filtered_attributes  = lt_filtered_attributes
                                                  iv_fill_data            = abap_true
                                        IMPORTING et_data                 = lt_desc
                                                  et_target_key           = lt_desc_key ).
      io_read->retrieve_by_association( EXPORTING iv_node                 = /iam/if_act_activity_c=>sc_node-description
                                                  it_key                  = lt_desc_key
                                                  iv_association          = /iam/if_act_activity_c=>sc_association-description-description_text_default
                                                  iv_fill_data            = abap_true
                                                  iv_before_image         = abap_false
                                        IMPORTING et_data                 = lt_hist_desc_text ).
      READ TABLE lt_hist_desc_text ASSIGNING FIELD-SYMBOL(<ls_desc>) INDEX 1.
      IF sy-subrc EQ 0.
        IF <ls_desc>-long_text_formatted IS INITIAL.
          DATA(lv_no_text) = abap_true.
        ENDIF.
      ELSE.
        lv_no_text = abap_true.
      ENDIF.
      IF lv_no_text IS NOT INITIAL.
        IF eo_message IS NOT BOUND.
          eo_message = /bobf/cl_frw_factory=>get_message( ).
        ENDIF.
*          data(lv_key) = value #( lt_desc_key[
        READ TABLE lt_desc_key ASSIGNING FIELD-SYMBOL(<ls_desc_key>) INDEX 1.
        IF sy-subrc EQ 0.
          DATA(lv_key) = <ls_desc_key>-key.
        ENDIF.
        ls_msg-msgid = 'MESSAGES'.
        ls_msg-msgno = '007'.
        ls_msg-msgty = 'E'.
        eo_message->add_message(
          EXPORTING
            is_msg       =  ls_msg
            iv_node      =  /iam/if_act_activity_c=>sc_node-description_text
            iv_key       =  lv_key
            iv_attribute = /iam/if_act_activity_c=>sc_node_attribute-description_text-long_text_formatted ).
        READ TABLE it_key ASSIGNING <ls_key> INDEX 1.
        IF sy-subrc EQ 0.
          APPEND INITIAL LINE TO et_failed_key ASSIGNING FIELD-SYMBOL(<ls_failed>).
          <ls_failed>-key = <ls_key>-key.
        ENDIF.
        RETURN.
      ENDIF.
    ENDIF.
*---- /Enhanced
