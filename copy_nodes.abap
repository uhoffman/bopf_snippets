METHOD /iam/if_create_child_cr~change_child_cr.
**---------------------------------------------------------------------*
** This functionality can copy the Questionaire from the
** parent change request to the child change request.
**---------------------------------------------------------------------*
*
**---------------------------------------------------------------------*
** data declaration
**---------------------------------------------------------------------*
  DATA: lo_service_manager_issue TYPE REF TO /bobf/if_tra_service_manager, "service manager change request
        lt_root_node_keys        TYPE        /bobf/t_frw_key, "table of change request root keys
        lr_s_root_node_key       TYPE REF TO /bobf/s_frw_key,  "reference to a root key
        lt_key                   TYPE /bobf/t_frw_key,
        lt_desc_parent           TYPE /iam/t_act_desc,
        lr_desc_parent           TYPE REF TO /iam/s_act_desc,
        lr_desc                  TYPE REF TO /iam/s_act_desc,
        lt_desc_child            TYPE /iam/t_act_desc,
        lr_desc_child            TYPE REF TO /iam/s_act_desc,
        lo_msg                   TYPE REF TO /bobf/if_frw_message. "message object

  DATA: lo_change         TYPE REF TO /bobf/if_tra_change,
        ls_modification   TYPE        /bobf/s_frw_modification,
        lt_modification   TYPE        /bobf/t_frw_modification,
        lt_changed_fields TYPE        /bobf/t_frw_name.

  DATA: lt_plant          TYPE        /iam/t_i_obj_ref,
        lr_s_plant_parent TYPE REF TO /iam/s_i_obj_ref,
        lr_child_act      TYPE REF TO /iam/s_act_root,
        lr_parent_act     TYPE REF TO /iam/s_act_root,
        lr_act            TYPE REF TO /iam/s_act_root.
**---------------------------------------------------------------------*
** implementation
**---------------------------------------------------------------------*
  "get message object
  eo_message = /bobf/cl_frw_factory=>get_message( ).
  "get service manager for change request
  lo_service_manager_issue = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /iam/if_i_issue_c=>sc_bo_key ).
  "get service manager for activity
  DATA(lo_service_manager_activity) = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /iam/if_act_activity_c=>sc_bo_key ).
  "build key table with parent and child
  APPEND INITIAL LINE TO lt_root_node_keys REFERENCE INTO lr_s_root_node_key.
  lr_s_root_node_key->key = iv_parent_root_key. "we want to read the parent root

  APPEND INITIAL LINE TO lt_root_node_keys REFERENCE INTO lr_s_root_node_key.
  lr_s_root_node_key->key = iv_child_root_key. "we want to read the child root

  DATA lt_act         TYPE  /iam/t_act_root.

  lo_service_manager_issue->retrieve_by_association(
      EXPORTING
        iv_node_key             =  /iam/if_i_issue_c=>sc_node-root   " Node
        it_key                  =  lt_root_node_keys  " Key Table
        iv_association          =  /iam/if_i_issue_c=>sc_association-root-all_activities
        iv_fill_data            =  abap_true
      IMPORTING
        et_data                 = lt_act
        eo_message              = lo_msg ).
  CLEAR: lt_changed_fields, ls_modification, lt_modification.

  LOOP AT lt_act REFERENCE INTO lr_child_act WHERE par_issue_uuid EQ iv_child_root_key.
    CLEAR: lt_changed_fields, lt_key.
    READ TABLE lt_act REFERENCE INTO lr_parent_act WITH KEY par_issue_uuid = iv_parent_root_key
                                                            act_template   = lr_child_act->act_template
                                                            act_type       = lr_child_act->act_type
                                                            act_category   = lr_child_act->act_category.
    IF sy-subrc EQ 0.
      IF is_codegroup( CONV #( lr_child_act->act_template ) ).
        APPEND INITIAL LINE TO lt_key ASSIGNING FIELD-SYMBOL(<ls_key>).
        <ls_key>-key = lr_parent_act->key.
        lo_service_manager_activity->retrieve_by_association(
            EXPORTING iv_node_key    = /iam/if_act_activity_c=>sc_node-root
                      it_key         = lt_key
                      iv_association = /iam/if_act_activity_c=>sc_association-root-description
                      iv_fill_data   = abap_true
            IMPORTING eo_message     = eo_message
                      et_data        = lt_desc_parent ).
        READ TABLE lt_desc_parent REFERENCE INTO lr_desc_parent WITH KEY desc_type = 'ARESP'.
        IF sy-subrc EQ 0.
          CLEAR   lt_key.
          APPEND INITIAL LINE TO lt_key ASSIGNING <ls_key>.
          <ls_key>-key = lr_child_act->key.
          lo_service_manager_activity->retrieve_by_association(
              EXPORTING iv_node_key    = /iam/if_act_activity_c=>sc_node-root
                        it_key         = lt_key
                        iv_association = /iam/if_act_activity_c=>sc_association-root-description
                        iv_fill_data   = abap_true
              IMPORTING eo_message     = eo_message
                        et_data        = lt_desc_child ).
          READ TABLE lt_desc_child REFERENCE INTO lr_desc_child WITH KEY desc_type = 'ARESP'.
          IF sy-subrc EQ 0.
            APPEND /iam/if_act_activity_c=>sc_node_attribute-description-code TO lt_changed_fields.
            APPEND /iam/if_act_activity_c=>sc_node_attribute-description-code_txt TO lt_changed_fields.
            ls_modification-change_mode     = /bobf/if_frw_c=>sc_modify_update.
            ls_modification-node            = /iam/if_act_activity_c=>sc_node-description.
            ls_modification-key             = lr_desc_child->key.
            ls_modification-changed_fields  = lt_changed_fields.
            CREATE DATA lr_desc.
            lr_desc->code = lr_desc_parent->code.
            lr_desc->code_txt = lr_desc_parent->code_txt.
            ls_modification-data            = lr_desc.
            APPEND ls_modification TO lt_modification.
          ENDIF.
        ENDIF.
      ELSE.
        APPEND /iam/if_act_activity_c=>sc_node_attribute-root-sel_crit_cd TO lt_changed_fields.
        APPEND /iam/if_act_activity_c=>sc_node_attribute-root-resp_val_bool TO lt_changed_fields.
        ls_modification-change_mode     = /bobf/if_frw_c=>sc_modify_update.
        ls_modification-node            = /iam/if_act_activity_c=>sc_node-root.
        ls_modification-key             = lr_child_act->key.
        ls_modification-changed_fields  = lt_changed_fields.
        CREATE DATA lr_act.
        lr_act->sel_crit_cd = lr_parent_act->sel_crit_cd.
        lr_act->resp_val_bool = lr_parent_act->resp_val_bool.
        ls_modification-data            = lr_act.
        APPEND ls_modification TO lt_modification.
      ENDIF.
    ENDIF.
  ENDLOOP.
  "add occured messages
  eo_message->add( lo_msg ).
  " Trigger Modify
  lo_service_manager_activity->modify(
    EXPORTING
      it_modification = lt_modification
    IMPORTING
      eo_change       = lo_change
      eo_message      = lo_msg ).
  "add occured messages
  eo_message->add( lo_msg ).
ENDMETHOD.
