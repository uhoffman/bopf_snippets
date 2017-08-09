    LOOP AT lt_ro_upload ASSIGNING <fs_ro_upload>.
      CREATE DATA lr_related_obj.
      MOVE-CORRESPONDING <fs_ro_upload> TO lr_related_obj->*.
      io_modify->create(
          EXPORTING
            iv_node             = /iam/if_i_issue_c=>sc_node-object_reference
            is_data             = lr_related_obj
            iv_assoc_key        = /iam/if_i_issue_c=>sc_association-root-objref
            iv_source_node_key  = /iam/if_i_issue_c=>sc_node-root
            iv_source_key       = lr_ro->parent_key
          IMPORTING
            ev_key              = lv_key ).
    ENDLOOP.
