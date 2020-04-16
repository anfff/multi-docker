proc ::rtsutils::addEvents {args} {
   parse args $args {
      -mode                   {-default "set" -enum {"set" "update"}}
      -input                  {-default "Schedules" -enum {"Schedules" "OrdersPlan" "Orders" "Orders_v2"}}
      -rows                   {-required}
      -row_pattern            {-default "object_tag"}
      -eventsDrawer           {-default ""}
      -timePickerFrom         {-required}
      -timePickerTo           {-required}
      -statusMapping          {-default ""}
      -session                {-default ""}
      -objectsEvent           {-default ""}
      -changeoversEvent       {-default ""}
      -changeoversBlock       {-default ""}
      -shiftsData             {-default ""}
      -periodicsBlock         {-default ""}
      -eventsState            {-default ""}
      -statesTemplate         {-default ""}
      -allStatesEvent         {-default ""}
      -multiple               {-default "0" -boolean}
      allEvents               {-required}
   }
   if {[antIsDebug]} {
      antDebugLog [info level 0]
      antSetModuleStatus warning "Debug mode may cause process increase memory use"
   }


   set eventsData [dict create]
   set color {}
   set modifiers ""
   set eventsOutOfRange [dict create]
   set eventsToRemove [dict create]
   set shiftContent [::av::html::button -icon "fal fa-arrow-circle-down" -height 100% -width 100% -styleColor PRIMARY -iconSize 20]
   set drawerCategories [list ]
   set drawerEvents [list
   set i 0
   set eventsOnCreatedLayer ""
   set stateBlock [dict create]
   if {$input eq "OrdersPlan"} {
      set keysMap [dict create start_time start_time\
                              end_time end_time\
                              planned_start planned_start\
                              planned_end planned_end\
                              quantity operation_quantity\
                              planned_quantity operation_planned_quantity\
                              equipment_tag object_tag\
                              system_status_tag system_status_tag\
                              status_tag status_tag\
                              item_tag item_tag\
                              operation_name operation_tag\
                              operation_local_name operation_tag\
                              item_name item_tag\
                              item_local_name item_tag\
                              order_name number\
                              cycle_time_s cycle_time_s\
                              sequence sequence\
                              efficiency efficiency\
                              minimum_delay_s minimum_delay_s\
                              maximum_delay_s maximum_delay_s\
                              fixed_time fixed_time\
                              event_type_tag order_level_tag\
                              fixed_sequence fixed_sequence\
                              with_barriers with_barriers\
                              occupy_object occupy_object\
                              priority_tag priority_tag]
   } elseif {$input eq "Schedules"} {
      set keysMap [dict create start_time start_time\
                              end_time end_time\
                              planned_start planned_start\
                              planned_end planned_end\
                              quantity quantity\
                              planned_quantity planned_quantity\
                              equipment_tag object_tag\
                              system_status_tag system_status_tag\
                              status_tag status_tag\
                              event_type_tag event_type_tag\
                              deadline deadline\
                              can_move can_move\
                              edited edited\
                              reject reject\
                              comment comment\
                              scenario_tag scenario_tag\
                              cycle_time_s [list properties BLOCK_CYCLE_TIME_S]\
                              sequence [list properties BLOCK_SEQUENCE]\
                              minimum_delay_s [list properties BLOCK_MINIMUM_DELAY_S]\
                              maximum_delay_s [list properties BLOCK_MAXIMUM_DELAY_S]\
                              operation_name [list properties EVENT_OPERATION_NAME]\
                              operation_local_name [list properties EVENT_OPERATION_LOCAL_NAME]\
                              item_code [list properties EVENT_ITEM_CODE]\
                              item_tag [list properties EVENT_ITEM_TAG]\
                              order_name [list properties EVENT_ORDER_NUMBER]\
                              item_name [list properties EVENT_ITEM_NAME]\
                              item_local_name [list properties EVENT_ITEM_LOCAL_NAME]\
                              efficiency [list properties BLOCK_EFFICIENCY]\
                              origin_planned_start [list properties BLOCK_ORIGIN_PLANNED_START]\
                              parent_event [list event_relations PARENT]\
                              fixed_time [list properties BLOCK_FIXED_TIME]\
                              fixed_sequence [list properties BLOCK_FIXED_SEQUENCE]\
                              with_barriers [list properties BLOCK_WITH_BARRIERS]\
                              prev_sequence [list relations PREV_SEQUENCE]\
                              occupy_object [list properties EVENT_OCCUPY_OBJECT]\
                              priority_tag [list properties BLOCK_PRIORITY_TAG]\
                              state_name [list properties EVENT_STATE_NAME]\
                              state_block_name [list properties BLOCK_STATE_NAME]\
                              location_tags location_tags]
   } elseif {$input eq "Orders"} {
      set keysMap [dict create start_time start_time\
                              end_time end_time\
                              planned_start planned_start\
                              planned_end planned_end\
                              quantity quantity\
                              planned_quantity planned_quantity\
                              equipment_tag object_tag\
                              system_status_tag status_tag\
                              item_code item_tag\
                              status_tag status_tag\
                              item_tag item_tag\
                              item_name item_tag\
                              item_local_name item_tag\
                              order_name number\
                              client_tag client_tag]
   } elseif {$input eq "Orders_v2"} {
       set keysMap [dict create start_time start_time\
                              end_time end_time\
                              planned_start planned_start\
                              planned_end planned_end\
                              quantity quantity\
                              planned_quantity planned_quantity\
                              equipment_tag object_tag\
                              system_status_tag status_tag\
                              item_code item_tag\
                              status_tag status_tag\
                              item_tag item_tag\
                              item_name item_tag\
                              item_local_name item_tag\
                              order_name number\
                              client_tag client_tag\
                              fixed_time fixed_time\
                              event_type_tag order_level_tag\
                              fixed_sequence fixed_sequence\
                              with_barriers with_barriers\
                              occupy_object occupy_object\
                              priority_tag priority_tag\
                              cycle_time_s cycle_time_s\
                              sequence sequence\
                              event_type_tag order_level_tag\
                              efficiency efficiency\
                              minimum_delay_s minimum_delay_s\
                              maximum_delay_s maximum_delay_s\
                              operation_name operation_name\
                              operation_local_name operation_local_name]
   }

   set operationName [dict getnull -- $keysMap operation_name]
   set operationLocalName [dict getnull -- $keysMap operation_local_name]
   set orderName [dict getnull -- $keysMap order_name]
   set itemName [dict getnull -- $keysMap item_name]
   set itemLocalName [dict getnull -- $keysMap item_local_name]
   set statusTag [dict getnull -- $keysMap status_tag]
   set quantity [dict getnull -- $keysMap quantity]
   set plannedQuantity [dict getnull -- $keysMap planned_quantity]
   set systemStatusTag [dict getnull -- $keysMap system_status_tag]
   set comment [dict getnull -- $keysMap comment]
   set deadline [dict getnull -- $keysMap deadline]
   set cycleTime [dict getnull -- $keysMap cycle_time_s]
   set sequence [dict getnull -- $keysMap sequence]
   set efficiency [dict getnull -- $keysMap efficiency]
   set minimumDelay [dict getnull -- $keysMap minimum_delay_s]
   set maximumDelay [dict getnull -- $keysMap maximum_delay_s]
   set originPlannedStart [dict getnull -- $keysMap origin_planned_start]
   set plannedEnd [dict getnull -- $keysMap planned_end]
   set plannedStart [dict getnull -- $keysMap planned_start]
   set startTime [dict getnull -- $keysMap start_time]
   set endTime [dict getnull -- $keysMap end_time]
   set equipmentTag [dict getnull -- $keysMap equipment_tag]
   set eventTypeTag [dict getnull -- $keysMap event_type_tag]
   set edited [dict getnull -- $keysMap edited]
   set canMove [dict getnull -- $keysMap can_move]
   set parentRelation [dict getnull -- $keysMap parent_event]
   set fixedTime [dict getnull -- $keysMap fixed_time]
   set fixedSequence [dict getnull -- $keysMap fixed_sequence]
   set withBarriers [dict getnull -- $keysMap with_barriers]
   set prevSequence [dict getnull -- $keysMap prev_sequence]
   set occupyObject [dict getnull -- $keysMap occupy_object]
   set priorityTag [dict getnull -- $keysMap priority_tag]
   set stateName [dict getnull -- $keysMap state_name]
   set locationTags [dict getnull -- $keysMap location_tags]
   set scenarioTag [dict getnull -- $keysMap scenario_tag]

   if {$eventsDrawer ne {} && $mode ne "update"} {
      dict for {eventId drawer} $eventsDrawer {
         set prompt [list $session -type "DRAWER" -data $drawer -keysMap $keysMap -statusMapping $statusMapping]
         set eventStartTime [dict getnull -- $drawer $startTime]
         if {$eventStartTime eq {}} {
            set eventStartTime [dict getnull -- $drawer $plannedStart]
         }
         set startTimeTs [antStrToTime $eventStartTime -with_timezone 1]
         set eventEndTime [dict getnull -- $drawer $endTime]
         if {$eventEndTime eq {}} {
           set eventEndTime [dict getnull -- $drawer $plannedEnd]
         }
         set endTimeTs [antStrToTime $eventEndTime -with_timezone 1]
         if {[dict get $drawer $systemStatusTag] in [dict getnull -- $statusMapping planned MES]} {
            set canDrag 1
         } else {
            set canDrag 0
         }
         dict for {name body} [dict get $statusMapping] {
            if {[dict get $drawer $systemStatusTag] in [dict get $body MES]} {
               set color [av::color::getColor [dict get $body Color]]
            }
         }
         if {[dict getnull -- $drawer $eventTypeTag] eq "MAINTENANCE_ORDER_STEP"} {
            if {$occupyObject ne "" && [dict getnull -- $drawer {*}$occupyObject] == 1} {
                set color [av::color::getColor ADDITIONAL_LIGHT]
            } else {
                set color [av::color::getColor ADDITIONAL_LIGHTER]
            }
            set content [::rtsutils::CreateEvent $session -type "MAINTENANCE" -data $drawer -keysMap $keysMap -statusMapping $statusMapping]
         } else {
            set content [::rtsutils::CreateEvent $session -type "WORK_ORDER" -data $drawer -keysMap $keysMap -statusMapping $statusMapping]
         }


         if {($drawerCategories == "" || [lsearch -all $drawerCategories [list [dict get $drawer $equipmentTag] -label [dict get $drawer $equipmentTag]]] == "")} {
            lappend drawerCategories [list [dict get $drawer $equipmentTag] -label [::utils::gui::langvalue -session $session -value [dict getnull -- $::rtsutils::EquipmentMap [dict get $drawer $equipmentTag] name] -local_value [dict getnull -- $::rtsutils::EquipmentMap [dict get $drawer $equipmentTag] local_name]]]
         }
         lappend drawerEvents [list $eventId \
                                    -color $color \
                                    -categoryId [dict get $drawer $equipmentTag] \
                                    -canDrag $canDrag \
                                    -height 50 \
                                    -content $content \
                                    -duration [expr {$endTimeTs - $startTimeTs}] \
                                    -promptProvider [list ::rtsutils::CreatePrompt {*}$prompt]]

      }
   }

    if {$statesTemplate ne ""} {
        lappend drawerCategories [list STATES -label [av::html::translate RTS_LAYER_TITLE_STATES]]
        dict for {eventTag eventBody} $statesTemplate {
            set content [::rtsutils::CreateEvent $session -type "STATE_TEMPLATE" -data $eventBody -keysMap $keysMap -statusMapping $statusMapping]
            set color [dict getnull -- $eventBody properties EVENT_COLOR]
            lappend drawerEvents [list $eventTag \
                                    -color $color \
                                    -categoryId STATES \
                                    -canDrag 1 \
                                    -height 50 \
                                    -content $content \
                                    -duration 10000]
        }
    }
    if {$drawerCategories ne ""} {
        dict set resultTimeline DRAWER_CATEGORIES $drawerCategories
    }
    if {$drawerEvents ne ""} {
        dict set resultTimeline DRAWER_SET $drawerEvents
    }

   dict for {eventId event} $allEvents {
      if {$multiple && [llength $row_pattern] == 2} {
        set row [string cat [dict getnull -- $event [lindex $row_pattern 0]] [dict getnull -- $event [lindex $row_pattern 1]]]
      } else {
        set row [dict getnull -- $event [lindex $row_pattern 0]]
      }
      if {$row ni $rows && $mode eq "update" || "TIMELINE" ni [dict getnull -- $event $locationTags] && $input eq "Schedules"} {continue}
      set eventStartTime [dict getnull -- $event $startTime]
      if {$eventStartTime eq {}} {
        set eventStartTime [dict getnull -- $event $plannedStart]
      }
      set layer ""
      set startTimeTs [antStrToTime $eventStartTime -with_timezone 1]
      set eventEndTime [dict getnull -- $event $endTime]
      if {$eventEndTime eq {}} {
        set eventEndTime [dict getnull -- $event $plannedEnd]
      }
      set endTimeTs [antStrToTime $eventEndTime -with_timezone 1]
      if {($startTimeTs > $timePickerTo || $endTimeTs < $timePickerFrom) && [dict getnull -- $event $systemStatusTag] ni "IN_PROGRESS"} {
         if {$mode eq "set"} {
            dict set eventsOutOfRange $eventId 1
            dict set eventsToRemove $eventId [list -id $eventId]
         } else {
            dict set eventsToRemove $eventId [list -id $eventId]
         }
         continue
      }
      set args ""
      switch -glob [dict getnull -- $event $eventTypeTag] {
          PRODUCTION -
          PRODUCTION_ORDER_STEP {
              switch [dict get $event $systemStatusTag] {
                  PLANNING -
                  RELEASED -
                  IN_PROGRESS -
                  CLOSED -
                  FINISHED {
                    set layer [expr {[dict exists $event layer] ? [dict get $event layer] : "operations"}]
                    if {[dict getnull -- $event $deadline] ne ""} {
                        set deadlineTs [antStrToTime [dict getnull -- $event $deadline] -with_timezone 1]
                    } else {
                        set deadlineTs ""
                    }
                    dict for {name body} [dict get $statusMapping] {
                        if {[dict get $event $systemStatusTag] in [dict get $body MES]} {
                            set color [av::color::getColor [dict get $body Color]]
                        }
                    }

                    set prompt [list $session -type "WORK_ORDER" -data $event -objectsEvent $objectsEvent -keysMap $keysMap -statusMapping $statusMapping -input $input]
                    if {[dict getnull -- $event $edited] == 1} {
                        lappend args -modified
                    }
                    if {$deadlineTs < $endTimeTs && $deadlineTs ne "" || [dict exists $event properties BLOCK_LACK_RESOURCE] || [dict exists $event properties BLOCK_EXCEEDS_INTERVAL]} {
                        lappend args -late
                    }
                    set content [::rtsutils::CreateEvent $session -type "WORK_ORDER" -data $event -keysMap $keysMap {*}$args -statusMapping $statusMapping -input $input]
                    set drawRedBorder 0
                    if {[dict exists $event labels]} {
                        dict for {labelTag labelBody} [dict get $event labels] {
                            if {[dict getnull -- $labelBody haveRedBorder] == 1} {
                                set drawRedBorder 1
                            }
                        }
                    }
                    if {[dict getnull -- $event {*}$minimumDelay] > [dict getnull -- $event {*}$maximumDelay]\
                            || [dict getnull -- $event properties BLOCK_FIXED_TIME_ERROR] == 1 || [dict getnull -- $event properties BLOCK_CANNOT_PLANNED] == 1 || $drawRedBorder} {
                        set css "border: 1px solid [av::color::getColor NEGATIVE]; pointer-events: auto;"
                    } else {
                        if {[dict exists $allStatesEvent [dict getnull -- $event $eventTypeTag]] && [dict get $event $systemStatusTag] in {PLANNING RELEASED IN_PROGRESS}} {
                            set stateBody [dict get $allStatesEvent [dict getnull -- $event $eventTypeTag]]
                            if {[dict get $event $systemStatusTag] eq "IN_PROGRESS"} {
                                dict set stateBlock ${eventId}_STATE planned_start [utils::converttime [clock seconds]]
                            } else {
                                dict set stateBlock ${eventId}_STATE planned_start $eventStartTime
                            }

                            dict set stateBlock ${eventId}_STATE planned_end $eventEndTime
                            dict set stateBlock ${eventId}_STATE properties EVENT_COLOR [dict get $stateBody properties EVENT_COLOR]
                            dict set stateBlock ${eventId}_STATE properties EVENT_STATE_NAME [dict get $stateBody properties EVENT_STATE_NAME]
                            dict set stateBlock ${eventId}_STATE system_status_tag [dict get $event $systemStatusTag]
                            dict set stateBlock ${eventId}_STATE event_row $row
                        }
                        set css "border-radius: 5px; border: 1px solid transparent; pointer-events: auto;"
                    }
                    if {[dict get $event $systemStatusTag] eq "PLANNING"} {
                        set canDrag 1
                    } else {
                        set canDrag 0
                    }

                  }
                  CREATED {
                    set layer [expr {[dict exists $event layer] ? [dict get $event layer] : "created"}]
                    if {$row ni $eventsOnCreatedLayer} {
                        lappend eventsOnCreatedLayer $row
                    }
                    if {[dict getnull -- $event $deadline] ne ""} {
                        set deadlineTs [antStrToTime [dict getnull -- $event $deadline] -with_timezone 1]
                    } else {
                        set deadlineTs ""
                    }
                    set prompt [list $session -type "WORK_ORDER" -data $event -objectsEvent $objectsEvent -keysMap $keysMap -statusMapping $statusMapping -input $input]
                    if {[dict getnull -- $event $edited] == 1} {
                        lappend args -modified
                    }
                    if {$deadlineTs < $endTimeTs && $deadlineTs ne "" || [dict exists $event properties BLOCK_LACK_RESOURCE] || [dict exists $event properties BLOCK_EXCEEDS_INTERVAL]} {
                        lappend args -late
                    }
                    set content [::rtsutils::CreateEvent $session -type "WORK_ORDER" -data $event -keysMap $keysMap {*}$args -statusMapping $statusMapping -descriptionLineContent $descriptionLineContent -headerLineContent $headerLineContent -input $input]
                    set css "pointer-events: auto;"
                    set color [av::color::getColor REGULAR_DISABLED]
                    set canDrag 1
                  }
              }
          }
          MAINTENANCE_ORDER_STEP -
          MAINTENANCE -
          GROUP {
              switch [dict get $event $systemStatusTag] {
                  PLANNING -
                  RELEASED -
                  IN_PROGRESS -
                  CLOSED -
                  FINISHED {
                    set layer [expr {[dict exists $event layer] ? [dict get $event layer] : "maintenance"}]
                    if {$prevSequence ne "" && [dict getnull -- $event {*}$prevSequence] ne ""} {
                        dict set event properties BLOCK_PREV_SEQUENCE_NAME [dict getnull -- $allEvents [dict get $event {*}$prevSequence] {*}$orderName]
                    }
                    set prompt [list $session -type "MAINTENANCE" -data $event -objectsEvent $objectsEvent -keysMap $keysMap -statusMapping $statusMapping -input $input]
                    if {[dict getnull -- $event $edited] == 1} {
                        lappend args -modified
                    }
                    if {[dict exists $event properties BLOCK_LACK_RESOURCE] || [dict exists $event properties BLOCK_EXCEEDS_INTERVAL]} {
                        lappend args -late
                    }

                    set content [::rtsutils::CreateEvent $session -type "MAINTENANCE" -data $event -keysMap $keysMap {*}$args -statusMapping $statusMapping -input $input]
                    if {[dict getnull -- $event properties BLOCK_FIXED_TIME_ERROR] == 1 || [dict getnull -- $event properties BLOCK_CANNOT_PLANNED] == 1} {
                        set css "border: 1px solid [av::color::getColor NEGATIVE]; pointer-events: auto;"
                    } else {
                        if {[dict exists $allStatesEvent [dict getnull -- $event $eventTypeTag]] && [dict get $event $systemStatusTag] in {PLANNING RELEASED IN_PROGRESS}} {
                            set stateBody [dict get $allStatesEvent [dict getnull -- $event $eventTypeTag]]
                            if {[dict get $event $systemStatusTag] eq "IN_PROGRESS"} {
                                dict set stateBlock ${eventId}_STATE planned_start [utils::converttime [clock seconds]]
                            } else {
                                dict set stateBlock ${eventId}_STATE planned_start $eventStartTime
                            }
                            dict set stateBlock ${eventId}_STATE planned_end $eventEndTime
                            dict set stateBlock ${eventId}_STATE properties EVENT_COLOR [dict get $stateBody properties EVENT_COLOR]
                            dict set stateBlock ${eventId}_STATE properties EVENT_STATE_NAME [dict get $stateBody properties EVENT_STATE_NAME]
                            dict set stateBlock ${eventId}_STATE system_status_tag [dict get $event $systemStatusTag]
                            dict set stateBlock ${eventId}_STATE event_row $row
                        }
                        set css "border-radius: 5px; border: 1px solid transparent; pointer-events: auto;"
                    }
                    if {$occupyObject ne "" && [dict getnull -- $event {*}$occupyObject] == 1} {
                        set color [av::color::getColor ADDITIONAL_LIGHT]
                    } else {
                        set color [av::color::getColor ADDITIONAL_LIGHTER]
                    }
                    if {[dict get $event $systemStatusTag] eq "PLANNING"} {
                        set canDrag 1
                    } else {
                        set canDrag 0
                    }
                  }
                  CREATED {
                    set layer [expr {[dict exists $event layer] ? [dict get $event layer] : "created"}]
                    if {$row ni $eventsOnCreatedLayer} {
                        lappend eventsOnCreatedLayer $row
                    }
                    set prompt [list $session -type "MAINTENANCE" -data $event -objectsEvent $objectsEvent -keysMap $keysMap -statusMapping $statusMapping -input $input]
                    if {[dict getnull -- $event $edited] == 1} {
                        lappend args -modified
                    }
                    if {[dict exists $event properties BLOCK_LACK_RESOURCE] || [dict exists $event properties BLOCK_EXCEEDS_INTERVAL]} {
                        lappend args -late
                    }
                    set content [::rtsutils::CreateEvent $session -type "MAINTENANCE" -data $event -keysMap $keysMap {*}$args -statusMapping $statusMapping -input $input]
                    set css "pointer-events: auto;"
                    set color [av::color::getColor REGULAR_DISABLED]
                    set canDrag 1
                  }
              }
          }
          *_STATE {
              set layer [expr {[dict exists $event layer] ? [dict get $event layer] : "operations"}]
              set prompt [list $session -type "STATE_BLOCK" -data $event -objectsEvent $objectsEvent -keysMap $keysMap -statusMapping $statusMapping -input $input]
              set content [::rtsutils::CreateEvent $session -type "STATE_BLOCK" -data $event -keysMap $keysMap -statusMapping $statusMapping]
              set color #f4f4f4

              if {[dict getnull -- $event properties BLOCK_FIXED_TIME_ERROR] == 1 || [dict getnull -- $event properties BLOCK_CANNOT_PLANNED] == 1} {
                  set css "border: 1px solid [av::color::getColor NEGATIVE]; pointer-events: auto;"
              } else {
                  set css "border-radius: 5px; border: 1px solid transparent; pointer-events: auto;"
              }
              set canDrag 1
              dict set eventsState ${eventId}_STATE $event
          }

      }

      if {$mode eq "set"} {

        dict set eventsData $eventId [list $eventId \
                            $startTimeTs \
                            $endTimeTs \
                            -rowId $row \
                            -height 50 \
                            -layer $layer \
                            -canDrag $canDrag \
                            -color $color \
                            -content $content \
                            -css $css \
                            -promptProvider [list ::rtsutils::CreatePrompt {*}$prompt]]

      } else {
         dict set eventsData $eventId [list -id $eventId \
                            -beginTs $startTimeTs \
                            -endTs $endTimeTs \
                            -height 50 \
                            -rowId $row \
                            -layer $layer \
                            -canDrag $canDrag \
                            -color $color \
                            -css $css \
                            -content $content \
                            -promptProvider [list ::rtsutils::CreatePrompt {*}$prompt]]
      }
   }

    dict for {eventId eventBody} $changeoversBlock {
        if {$multiple && [llength $row_pattern] == 2} {
          set row [string cat [dict getnull -- $eventBody [lindex $row_pattern 0]] [dict getnull -- $eventBody [lindex $row_pattern 1]]]
        } else {
          set row [dict getnull -- $eventBody [lindex $row_pattern 0]]
        }
        if {$row ni $rows} {continue}
        set eventStartTime [dict getnull -- $eventBody $plannedStart]
        set startTimeTs [antStrToTime $eventStartTime -with_timezone 1]
        set eventEndTime [dict getnull -- $eventBody $plannedEnd]
        set endTimeTs [antStrToTime $eventEndTime -with_timezone 1]
        if {($startTimeTs > $timePickerTo || $endTimeTs < $timePickerFrom) && [dict getnull -- $eventBody $systemStatusTag] ni "IN_PROGRESS"} {
            if {$mode eq "set"} {
                dict set eventsOutOfRange $eventId 1
                dict set eventsToRemove $eventId [list -id $eventId]
            } else {
                dict set eventsToRemove $eventId [list -id $eventId]
            }
            continue
        }
        set color #ffc98f
        set content [::rtsutils::CreateEvent $session -type "CHANGEOVER" -data $eventBody -keysMap $keysMap -statusMapping $statusMapping]
        set prompt [list $session -type CHANGEOVER -data $eventBody -objectsEvent $objectsEvent -changeoversEvent $changeoversEvent -keysMap $keysMap -statusMapping $statusMapping -input $input]
        if {[dict exists $allStatesEvent [dict getnull -- $eventBody $eventTypeTag]] && [dict get $eventBody $systemStatusTag] in {PLANNING RELEASED IN_PROGRESS}} {
            set stateBody [dict get $allStatesEvent [dict getnull -- $event $eventTypeTag]]
            if {[dict get $eventBody $systemStatusTag] eq "IN_PROGRESS"} {
                dict set stateBlock ${eventId}_STATE planned_start [utils::converttime [clock seconds]]
            } else {
                dict set stateBlock ${eventId}_STATE planned_start $eventStartTime
            }
            dict set stateBlock ${eventId}_STATE planned_end $eventEndTime
            dict set stateBlock ${eventId}_STATE properties EVENT_COLOR [dict get $stateBody properties EVENT_COLOR]
            dict set stateBlock ${eventId}_STATE properties EVENT_STATE_NAME [dict get $stateBody properties EVENT_STATE_NAME]
            dict set stateBlock ${eventId}_STATE system_status_tag [dict get $eventBody $systemStatusTag]
            dict set stateBlock ${eventId}_STATE event_row $row
        }
        set css "pointer-events: auto; border-radius: 5px; cursor: default;"
        if {$mode eq "set"} {
             dict set eventsData $eventId [list $eventId \
                                  $startTimeTs \
                                  $endTimeTs \
                                 -rowId $row \
                                 -height 50 \
                                 -layer changeovers \
                                 -canDrag 0 \
                                 -color $color \
                                 -content $content \
                                 -css $css \
                                 -promptProvider [list ::rtsutils::CreatePrompt {*}$prompt]]
        } else {
            dict set eventsData $eventId [list -id $eventId \
                                -beginTs $startTimeTs \
                                -endTs $endTimeTs \
                                -height 50 \
                                -rowId $row \
                                -layer changeovers \
                                -canDrag 0 \
                                -color $color \
                                -css $css \
                                -content $content \
                                -promptProvider [list ::rtsutils::CreatePrompt {*}$prompt]]
        }
   }
    dict for {eventId eventBody} $shiftsData {
        if {$multiple && [llength $row_pattern] == 2} {
          set row [string cat [dict getnull -- $eventBody [lindex $row_pattern 0]] [dict getnull -- $eventBody [lindex $row_pattern 1]]]
        } else {
          set row [dict getnull -- $eventBody [lindex $row_pattern 0]]
        }
        if {$row ni $rows} {continue}
        set eventStartTime [dict getnull -- $eventBody $plannedStart]
        set startTimeTs [antStrToTime $eventStartTime -with_timezone 1]
        set eventEndTime [dict getnull -- $eventBody $plannedEnd]
        set endTimeTs [antStrToTime $eventEndTime -with_timezone 1]
        if {($startTimeTs > $timePickerTo || $endTimeTs < $timePickerFrom) && [dict getnull -- $eventBody $systemStatusTag] ni "IN_PROGRESS"} {
            if {$mode eq "set"} {
                dict set eventsOutOfRange $eventId 1
                dict set eventsToRemove $eventId [list -id $eventId]
            } else {
                dict set eventsToRemove $eventId [list -id $eventId]
            }
            continue
        }
        set content ""
        set prompt ""
        set color #f4f4f4
        set css "pointer-events: auto; cursor: default;"
        if {[dict exists $allStatesEvent [dict getnull -- $eventBody $eventTypeTag]] && [dict get $eventBody $systemStatusTag] in {PLANNING RELEASED IN_PROGRESS}} {
            set stateBody [dict get $allStatesEvent [dict getnull -- $event $eventTypeTag]]
            if {[dict get $eventBody $systemStatusTag] eq "IN_PROGRESS"} {
                dict set stateBlock ${eventId}_STATE planned_start [utils::converttime [clock seconds]]
            } else {
                dict set stateBlock ${eventId}_STATE planned_start $eventStartTime
            }
            dict set stateBlock ${eventId}_STATE planned_end $eventEndTime
            dict set stateBlock ${eventId}_STATE properties EVENT_COLOR [dict get $stateBody properties EVENT_COLOR]
            dict set stateBlock ${eventId}_STATE properties EVENT_STATE_NAME [dict get $stateBody properties EVENT_STATE_NAME]
            dict set stateBlock ${eventId}_STATE system_status_tag [dict get $eventBody $systemStatusTag]
            dict set stateBlock ${eventId}_STATE event_row $row
        }
        dict lappend modifiers $row [list -from $startTimeTs -to $endTimeTs -color $color]
        if {$mode eq "set"} {
            dict set eventsData $eventId [list $eventId \
                                    $startTimeTs \
                                    $endTimeTs \
                                    -rowId $row \
                                    -height 50 \
                                    -layer shifts \
                                    -canDrag 0 \
                                    -color $color \
                                    -content $content \
                                    -css $css]
        } else {
            dict set eventsData $eventId [list -id $eventId \
                                -beginTs $startTimeTs \
                                -endTs $endTimeTs \
                                -rowId $row \
                                -height 50 \
                                -layer shifts \
                                -canDrag 0 \
                                -color $color \
                                -content $content \
                                -css $css]

        }
    }
    dict for {eventId eventBody} $periodicsBlock {
        if {$multiple && [llength $row_pattern] == 2} {
          set row [string cat [dict getnull -- $eventBody [lindex $row_pattern 0]] [dict getnull -- $eventBody [lindex $row_pattern 1]]]
        } else {
          set row [dict getnull -- $eventBody [lindex $row_pattern 0]]
        }
        set eventStartTime [dict getnull $eventBody $plannedStart]
        set startTimeTs [utils::converttime -result timestamp $eventStartTime]
        set eventEndTime [dict getnull $eventBody $plannedEnd]
        set endTimeTs [utils::converttime -result timestamp $eventEndTime]
        set name [dict getnull $eventBody names]
        set prompt [list $session -type PERIODIC -data $eventBody -objectsEvent $objectsEvent -changeoversEvent $changeoversEvent -keysMap $keysMap -statusMapping $statusMapping -input $input]
        set color #ffffff
        dict lappend modifiers $row [list -from $startTimeTs -to $endTimeTs -color $color -promptProvider [list ::rtsutils::CreatePrompt {*}$prompt]]
    }

    set eventsState [dict merge $eventsState $stateBlock]

    dict for {eventId eventBody} $eventsState {
        set row [dict get eventBody event_row]
        set content ""
        set eventStartTime [dict getnull -- $eventBody $startTime]
        if {$eventStartTime eq {}} {
            set eventStartTime [dict getnull -- $eventBody $plannedStart]
        }
        set layer ""
        set startTimeTs [antStrToTime $eventStartTime -with_timezone 1]
        set eventEndTime [dict getnull -- $eventBody $endTime]
        if {$eventEndTime eq {}} {
            set eventEndTime [dict getnull -- $eventBody $plannedEnd]
        }
        set endTimeTs [antStrToTime $eventEndTime -with_timezone 1]
        if {($startTimeTs > $timePickerTo || $endTimeTs < $timePickerFrom) && [dict getnull -- $event $systemStatusTag] ni "IN_PROGRESS"} {
            if {$mode eq "set"} {
                dict set eventsOutOfRange $eventId 1
                dict set eventsToRemove $eventId [list -id $eventId]
            } else {
                dict set eventsToRemove $eventId [list -id $eventId]
            }
            continue
        }
        set prompt [list $session -type "STATE" -data $eventBody -keysMap $keysMap -statusMapping $statusMapping]
        set color #f4f4f4
        set css "pointer-events: auto; border-radius: 2px; border:none; cursor: default;"
        if {$mode eq "set"} {
            dict set eventsData $eventId [list $eventId \
                                $startTimeTs \
                                $endTimeTs \
                                -rowId $row \
                                -height auto \
                                -layer states\
                                -canDrag 0 \
                                -color $color \
                                -content $content \
                                -css $css \
                                -promptProvider [list ::rtsutils::CreatePrompt {*}$prompt]]
        } else {
             dict set eventsData $eventId [list -id $eventId \
                                -beginTs $startTimeTs \
                                -endTs $endTimeTs \
                                -height auto \
                                -rowId $row \
                                -layer states \
                                -canDrag 0 \
                                -color $color \
                                -css $css \
                                -content $content\
                                -promptProvider [list ::rtsutils::CreatePrompt {*}$prompt]]
        }
    }

   dict set resultTimeline EVENTS [dict values $eventsData]

   if {$eventsToRemove ne ""} {
      dict set resultTimeline EVENTS_REMOVE [dict values $eventsToRemove]
   }

   set rowToModify {}
   dict for {row body} $modifiers {
      lappend modifRows [list -id $row -modifiers $body]
      lappend rowToModify $row
   }

   if {[info exists modifRows]} {
      dict set resultTimeline ROWS_UPDATE $modifRows
   }

   dict set resultTimeline EVENTS_ON_CREATED $eventsOnCreatedLayer


   if {$mode eq "set"} {
      dict set resultTimeline EVENTS_OUT_RANGE $eventsOutOfRange
   } else {
      dict set resultTimeline EVENTS_OUT_RANGE $eventsToRemove
   }
   return $resultTimeline
}
