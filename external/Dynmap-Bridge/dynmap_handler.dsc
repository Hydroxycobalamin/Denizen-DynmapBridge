dynmap_update_markers:
    type: world
    debug: false
    events:
        on system time minutely every:15:
        - run dynmap_task
dynmap_task:
    type: task
    debug: false
    script:
    - foreach <script[dynmap_config].data_key[configs]> key:name as:options:
        - define world <world[<[options.world]>].if_null[null]>
        - if <[world]> == null:
            - announce to_console "<red>WARNING: <white>World '<[options.world].color[dark_red]>' does not exist or isn't loaded!"
            - foreach next
        - foreach <[options.path]> as:path:
            - if !<[world].has_flag[<[path]>]>:
                - announce to_console "World '<[world].name.color[gold]>' does not contain the flag <[path].color[aqua]>"
                - foreach next
            - foreach <[world].flag[<[path]>]> as:note_name:
                - if <[note_name].as_cuboid.exists>:
                    - define area <cuboid[<[note_name]>]>
                    - execute as_server "dmarker addcorner <[area].min.simple.replace_text[,].with[ ]>" silent
                    - execute as_server "dmarker addcorner <[area].max.simple.replace_text[,].with[ ]>" silent
                    - inject dynmap_add_area
                - else if <[note_name].as_polygon.exists>:
                    - define area <polygon[<[note_name]>]>
                    - foreach "<[area].corners.parse[simple.replace_text[,].with[ ]]>" as:corner:
                        - execute as_server "dmarker addcorner <[corner]>" silent
                    - inject dynmap_add_area
                - else if !<[note_name].as_ellipsoid.exists>:
                    - announce to_console "<red>WARNING: <white>Path: <[path].color[aqua]> in world: <[world].name.color[gold]> does not contain a AreaObject '<[note_name].color[dark_red]>'"
                    - foreach next
                - inject dynmap_markers
    - run dynmap_remove_area
dynmap_add_area:
    type: task
    debug: false
    script:
    - define set <[options.marker-set].exists.if_true[set:<[options.marker-set]>].if_false[<empty>]>
    - execute as_server "dmarker deletearea id:<[note_name]> <[set]>" silent
    - execute as_server "dmarker addarea id:<[note_name]> <[set]> label:"<script[dynmap_config].parsed_key[configs.<[name]>.label].space_separated.if_null[<empty>]>"" silent
    - execute as_server "dmarker updatearea id:<[note_name]> <[set]> color:<[options.color].if_null[c7ba75]> fillcolor:<[options.fillcolor].if_null[feee97]> opacity:<[options.opacity].if_null[1]> fillopacity:<[options.fillopacity].if_null[0.5]> weight:<[options.weight].if_null[2]>" silent
    - execute as_server "dmarker clearcorners" silent
dynmap_markers:
    type: task
    debug: false
    script:
    - define marker-set <[options.marker-set].exists.if_true[<[options.marker-set]>].if_false[Markers]>
    - if !<server.flag[dynmap.areamarkers.<[marker-set]>].if_null[<list>].contains[<[note_name]>]>:
        - flag server dynmap.areamarkers.<[marker-set]>:->:<[note_name]>
    - flag server dynmap.check.<[marker-set]>:->:<[note_name]>
dynmap_remove_area:
    type: task
    debug: false
    script:
    - foreach <server.flag[dynmap.areamarkers].if_null[<list>]> key:set as:areas:
        - foreach <[areas]> as:area:
            - if <server.flag[dynmap.check.<[set]>].contains[<[area]>].if_null[false]>:
                - foreach next
            - flag server dynmap.areamarkers.<[set]>:<-:<[area]>
            - if <[set]> == Markers:
                - execute as_server "dmarker deletearea id:<[area]>" silent
                - foreach next
            - execute as_server "dmarker deletearea id:<[area]> set:<[set]>" silent
    - flag server dynmap.check:!