    DATA lt_failed_key          LIKE et_failed_key.
    DATA lt_root                TYPE /iam/t_i_root.
    DATA ls_root                TYPE /iam/s_i_root.
    DATA lt_key                 TYPE /bobf/t_frw_key.
    DATA lr_root                LIKE REF TO ls_root.
    DATA lt_objref      TYPE         /iam/t_i_obj_ref.
    DATA lr_objref      TYPE REF TO  /iam/s_i_obj_ref.
    DATA lt_chg_flds    TYPE         /bobf/t_frw_name.

    " Ermitterln der Änderungsnummer und füllen des Objekts
*FIELD-SYMBOLS <ls_key> type /BOBF/s_FRW_KEY.

    CASE is_ctx-act_key.
      WHEN /iam/if_i_issue_c=>sc_action-root-approve_moc.
        io_read->retrieve( EXPORTING  iv_node       = is_ctx-node_key
                                      it_key        = it_key
                                      iv_fill_data  = abap_true
                           IMPORTING  et_data       = lt_root
                                      et_failed_key = lt_failed_key ).
        LOOP AT lt_root REFERENCE INTO lr_root.
          APPEND INITIAL LINE TO lt_key ASSIGNING FIELD-SYMBOL(<ls_key>).
          <ls_key>-key = lr_root->key.
        ENDLOOP.
        io_read->retrieve_by_association( EXPORTING iv_node        = /iam/if_i_issue_c=>sc_node-root
                                                    it_key         = lt_key
                                                    iv_association = /iam/if_i_issue_c=>sc_association-root-objref_related_objects
                                                    iv_fill_data   = abap_true
                                          IMPORTING et_data        = lt_objref ).
        LOOP AT lt_objref REFERENCE INTO lr_objref.
          lr_objref->aennr = 'test'.
          APPEND 'AENNR' TO lt_chg_flds.
          CALL METHOD io_modify->update
            EXPORTING
              iv_node           = /iam/if_i_issue_c=>sc_node-object_reference
              iv_key            = lr_objref->key
              is_data           = lr_objref
              it_changed_fields = lt_chg_flds.


        ENDLOOP.

    ENDCASE.
