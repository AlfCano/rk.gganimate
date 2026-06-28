local({
  # =========================================================================================
  # 1. Package Definition and Metadata
  # =========================================================================================
  require(rkwarddev)
  rkwarddev.required("0.10-3")

  package_about <- rk.XML.about(
    name = "rk.gganimate",
    author = person(
      given = "Alfonso",
      family = "Cano",
      email = "alfonso.cano@correo.buap.mx",
      role = c("aut", "cre")
    ),
    about = list(
      desc = "Data preparation and generation of animated bubble charts (Gapminder style) using srvyr and gganimate.",
      version = "0.0.4",
      url = "https://github.com/AlfCano/rk.gganimate",
      license = "GPL (>= 3)"
    )
  )

  dependencies_node <- rk.XML.dependencies(
    dependencies = list(R.min = "3.5.0"),
    package = list(
      c(name = "ggplot2"),
      c(name = "gganimate"),
      c(name = "gifski"),
      c(name = "transformr"),
      c(name = "srvyr"),
      c(name = "dplyr")
    )
  )

  js_helpers <- "
    function getCol(id) {
        var raw = getValue(id);
        if (!raw) return 'NULL';
        var parts = raw.split(/[\\[\\]\\$]+/).filter(Boolean);
        if (parts.length > 0) {
            var last = parts[parts.length - 1];
            return last.replace(/[\"']/g, '');
        }
        return raw;
    }

    // NUEVA FUNCIÓN: Procesa selección múltiple y devuelve un array limpio
    function getCleanArray(id) {
        var rawValue = getValue(id);
        if (!rawValue) return [];
        var raw = rawValue.split(/\\n/).filter(Boolean);
        return raw.map(function(item) {
            var parts = item.split(/[\\[\\]\\$]+/).filter(Boolean);
            var last = parts[parts.length - 1];
            return last.replace(/[\"']/g, '');
        });
    }
  "

  # =========================================================================================
  # 2. COMPONENTE SECUNDARIO: Data Prep (srvyr 3D Data Extractor)
  # =========================================================================================

  var_sel_prep <- rk.XML.varselector(id.name = "v_sel_prep")
  prep_svy <- rk.XML.varslot("Survey Design Object", source = "v_sel_prep", required = TRUE, classes = "survey.design", id.name = "prep_svy")
  prep_time <- rk.XML.varslot("1. Time Variable (e.g., year)", source = "v_sel_prep", required = TRUE, id.name = "prep_time")
  prep_group <- rk.XML.varslot("2. Group Variable(s) (e.g., ent, sec_est)", source = "v_sel_prep", required = TRUE, multi = TRUE, id.name = "prep_group")
  prep_y <- rk.XML.varslot("3. Y-Axis: Numeric Variable for Mean (e.g., ingocup)", source = "v_sel_prep", required = TRUE, id.name = "prep_y")
  prep_x_cat <- rk.XML.varslot("4. X-Axis: Categorical Variable for % (e.g., seg_soc)", source = "v_sel_prep", required = TRUE, id.name = "prep_x_cat")
  prep_x_lvl <- rk.XML.input("Target Category Level for % (e.g., Sin acceso)", required = TRUE, id.name = "prep_x_lvl")
  prep_filter <- rk.XML.input("Optional: dplyr::filter condition (e.g., clase1 == 'Población económicamente activa')", id.name = "prep_filter")
  prep_save <- rk.XML.saveobj("Save summarized table as", initial = "tabla_animacion", chk = TRUE, id.name = "prep_save")

  dialog_prep <- rk.XML.dialog(
    label = "Data Prep for Animation (srvyr)",
    child = rk.XML.row(
      var_sel_prep,
      rk.XML.tabbook(tabs = list(
        "Data & Grouping" = rk.XML.col(
          rk.XML.frame(prep_svy, prep_filter, label = "Source Data & Filters"),
          rk.XML.frame(prep_time, prep_group, label = "Grouping Dimensions")
        ),
        "Metrics (X & Y)" = rk.XML.col(
          rk.XML.frame(prep_y, label = "Continuous Dimension (Calculates Mean)"),
          rk.XML.frame(prep_x_cat, prep_x_lvl, label = "Proportion Dimension (Calculates %)")
        ),
        "Output" = rk.XML.col(
          rk.XML.text("<b>Note:</b> Bubble size (Population Total) is calculated automatically based on the survey weights."),
          prep_save
        )
      ))
    )
  )

  js_calc_prep <- paste(js_helpers, "
    var svy = getValue('prep_svy');
    if (!svy) return;
    var time = getCol('prep_time');

    // NUEVA LÓGICA: Procesa múltiples grupos y crea la sintaxis de R
    var grp_array = getCleanArray('prep_group');
    var grp = grp_array.join(', '); // ej: 'ent, sec_est'
    var grp_na_checks = grp_array.map(function(g) { return '!is.na(' + g + ')'; }).join(', ');

    var y_var = getCol('prep_y');
    var x_cat = getCol('prep_x_cat');
    var x_lvl = getValue('prep_x_lvl');
    var filter_cond = getValue('prep_filter');

    echo(\"cat('Calculating summarized 3D data. This might take a few minutes...\\\\n')\\n\");

    echo(\"tabla_animacion <- srvyr::as_survey(\" + svy + \") %>%\\n\");

    if (filter_cond !== '') {
        echo(\"  dplyr::filter(\" + filter_cond + \") %>%\\n\");
    }

    echo(\"  dplyr::filter(!is.na(\" + time + \"), \" + grp_na_checks + \") %>%\\n\");
    echo(\"  dplyr::group_by(\" + time + \", \" + grp + \") %>%\\n\");
    echo(\"  dplyr::summarise(\\n\");
    echo(\"    bubble_size = srvyr::survey_total(na.rm = TRUE),\\n\");
    echo(\"    y_mean = srvyr::survey_mean(\" + y_var + \", na.rm = TRUE),\\n\");
    echo(\"    x_pct = srvyr::survey_mean(\" + x_cat + \" == '\" + x_lvl + \"', na.rm = TRUE) * 100\\n\");
    echo(\"  ) %>%\\n\");
    echo(\"  dplyr::select(\" + time + \", \" + grp + \", bubble_size, y_mean, x_pct)\\n\\n\");

    echo(\"cat('Done! The table tabla_animacion is ready for rk.gganimate.\\\\n')\\n\");
  ", sep = "\n")

  js_print_prep <- "echo(\"rk.header('Animation Data Prep completed')\\n\");"
  comp_prep <- rk.plugin.component("1. Data Prep for Animation", xml = list(dialog = dialog_prep), js = list(require = c("srvyr", "dplyr"), calculate = js_calc_prep, printout = js_print_prep), hierarchy = list("Survey", "Graphs", "Animations"))

  # =========================================================================================
  # 3. PLUGIN PRINCIPAL: Animated Bubble Chart (Storytelling)
  # =========================================================================================

  var_sel_anim <- rk.XML.varselector(id.name = "v_sel_anim")

  inp_df <- rk.XML.varslot("Data Frame (Summarized data is recommended)", source = "v_sel_anim", required = TRUE, classes = "data.frame", id.name = "inp_df")
  inp_x <- rk.XML.varslot("X Axis (Numeric)", source = "v_sel_anim", required = TRUE, id.name = "inp_x")
  inp_y <- rk.XML.varslot("Y Axis (Numeric)", source = "v_sel_anim", required = TRUE, id.name = "inp_y")
  inp_time <- rk.XML.varslot("Time / Frame Variable (e.g., Year)", source = "v_sel_anim", required = TRUE, id.name = "inp_time")
  inp_size <- rk.XML.varslot("Bubble Size (Optional)", source = "v_sel_anim", required = FALSE, id.name = "inp_size")
  inp_color <- rk.XML.varslot("Color / Group Category (Optional)", source = "v_sel_anim", required = FALSE, id.name = "inp_color")

   # NUEVO CAMPO DE FILTRO
  anim_filter <- rk.XML.input("Optional: dplyr::filter condition (e.g., sec_est == 'Manufactura')", id.name = "anim_filter")

 # LA CAJA DEBE ESTAR ADENTRO DE ESTE rk.XML.col
  tab_data <- rk.XML.col(inp_df, anim_filter, inp_x, inp_y, inp_time, inp_size, inp_color)

 inp_title <- rk.XML.input("Main Title", initial = "Evolution over time", id.name = "inp_title")
  inp_sub <- rk.XML.input("Subtitle (Use {frame_time} to display the dynamic year)", initial = "Year: {frame_time}", id.name = "inp_sub")
  inp_xlab <- rk.XML.input("X Axis Label", id.name = "inp_xlab")
  inp_ylab <- rk.XML.input("Y Axis Label", id.name = "inp_ylab")
  inp_leg_title <- rk.XML.input("Color Legend Title (Leave empty to use variable label)", id.name = "inp_leg_title")

  # NUEVO: Campo para el Caption
  inp_caption <- rk.XML.input("Caption (Source, credits, etc.)", id.name = "inp_caption")

  drop_pal <- rk.XML.dropdown("Color Palette", id.name = "drop_pal", options = list("Set1" = list(val = "Set1", chk = TRUE), "Dark2" = list(val = "Dark2"), "Paired" = list(val = "Paired"), "Spectral" = list(val = "Spectral")))
  chk_legend <- rk.XML.cbox("Show Color Legend", value = "1", chk = FALSE, id.name = "chk_legend")
  drop_theme <- rk.XML.dropdown("Plot Theme", id.name = "drop_theme", options = list("Minimal" = list(val = "theme_minimal", chk = TRUE), "Classic" = list(val = "theme_classic"), "Light" = list(val = "theme_light"), "Void" = list(val = "theme_void")))

  # NUEVO: Spinbox para el tamaño general de la fuente
  spin_base_size <- rk.XML.spinbox("Base Font Size (px)", min = 6, max = 36, initial = 14, id.name = "spin_base_size")

  chk_story <- rk.XML.cbox("Highlight specific bubbles (Storytelling)", value = "1", chk = FALSE, id.name = "chk_story")
  inp_target <- rk.XML.input("Exact name(s) to track (comma separated, e.g., Puebla, Tlaxcala)", id.name = "inp_target")
  frame_story <- rk.XML.frame(chk_story, inp_target, label = "Storytelling: Follow Bubbles")

  # Añadimos los nuevos campos a sus respectivas columnas
    # 1. Pestaña exclusiva para Etiquetas (Izquierda)
tab_labels <- rk.XML.col(
    inp_title,
    inp_sub,
    inp_xlab,
    inp_ylab,
    inp_leg_title,
    inp_caption,    # <--- AÑADIDO AQUÍ
    rk.XML.stretch()
  )

  # 2. Pestaña exclusiva para Tema y Storytelling (Derecha)
  tab_theme <- rk.XML.col(
    drop_pal,
    chk_legend,
    drop_theme,
    spin_base_size,
    frame_story,
    rk.XML.stretch()
  )

  spin_fps <- rk.XML.spinbox("Frames per second (FPS)", min = 1, max = 50, initial = 10, id.name = "spin_fps")
  spin_dur <- rk.XML.spinbox("Duration (Seconds)", min = 2, max = 60, initial = 10, id.name = "spin_dur")
  spin_w <- rk.XML.spinbox("Width (px)", min = 200, max = 2000, initial = 800, id.name = "spin_w")
  spin_h <- rk.XML.spinbox("Height (px)", min = 200, max = 2000, initial = 600, id.name = "spin_h")
  save_file <- rk.XML.browser("Save GIF as", type = "savefile", required = TRUE, initial = "animated_chart.gif", id.name = "save_file")

  tab_anim <- rk.XML.col(rk.XML.frame(spin_fps, spin_dur, label = "Animation Settings"), rk.XML.frame(spin_w, spin_h, label = "Dimensions"), save_file)

  # 3. Actualizamos el Tabbook para que ahora tenga 4 pestañas en lugar de 3
  dialog_gganim <- rk.XML.dialog(
    label = "Animated Bubble Chart",
    child = rk.XML.row(
      var_sel_anim,
      rk.XML.tabbook(tabs = list(
        "Variables" = tab_data,
        "Labels" = tab_labels,              # Nueva pestaña 2
        "Theme & Tracking" = tab_theme,     # Nueva pestaña 3
        "Render & Export" = tab_anim
      ))
    )
  )

  # ==================================

js_calc_anim <- paste(js_helpers, "
    var df = getValue('inp_df'); if (!df) return;
    var x = getCol('inp_x'); var y = getCol('inp_y'); var time = getCol('inp_time'); var sz = getCol('inp_size'); var col = getCol('inp_color');

    var title = getValue('inp_title'); var sub = getValue('inp_sub'); var xlab = getValue('inp_xlab'); var ylab = getValue('inp_ylab');
    var leg_title = getValue('inp_leg_title');
    var caption = getValue('inp_caption');

    var pal = getValue('drop_pal'); var theme = getValue('drop_theme'); var show_leg = getValue('chk_legend');
    var base_sz = getValue('spin_base_size');

    var story = getValue('chk_story'); var target = getValue('inp_target');
    var anim_filt = getValue('anim_filter');

    var fps = getValue('spin_fps'); var dur = getValue('spin_dur'); var w = getValue('spin_w'); var h = getValue('spin_h'); var path = getValue('save_file');

    // LÓGICA DE FILTRADO CORREGIDA
    if (anim_filt !== '') {
        echo(\"plot_data <- \" + df + \" %>% dplyr::filter(\" + anim_filt + \")\\n\");
    } else {
        echo(\"plot_data <- \" + df + \"\\n\");
    }

    var aes_call = \"x = \" + x + \", y = \" + y;
    if (sz !== 'NULL') aes_call += \", size = \" + sz;
    if (col !== 'NULL') aes_call += \", color = \" + col;

    // A partir de aquí, TODO usa 'plot_data'
    echo(\"p <- ggplot2::ggplot(plot_data, ggplot2::aes(\" + aes_call + \")) +\\n\");
    echo(\"  ggplot2::geom_point(alpha = 0.75, stroke = 1)\\n\\n\");

    if (sz !== 'NULL') {
        echo(\"p <- p + ggplot2::scale_size(range = c(3, 30), guide = 'none')\\n\");
    }

    if (col !== 'NULL') {
        echo(\"\\n# Palette Logic for multiple groups\\n\");
        echo(\"n_colors <- length(unique(stats::na.omit(plot_data[['\" + col + \"']])))\\n\");
        echo(\"if(n_colors <= 8) {\\n\");
        echo(\"  p <- p + ggplot2::scale_color_brewer(palette = '\" + pal + \"')\\n\");
        echo(\"} else {\\n\");
        echo(\"  my_pal <- grDevices::colorRampPalette(RColorBrewer::brewer.pal(8, '\" + pal + \"'))(n_colors)\\n\");
        echo(\"  p <- p + ggplot2::scale_color_manual(values = my_pal)\\n\");
        echo(\"}\\n\\n\");
    }

    // LÓGICA DE STORYTELLING (GEOM_LABEL MULTIPLE) USANDO plot_data
    if (col !== 'NULL' && story === '1' && target !== '') {
        var target_array = target.split(',').map(function(item) {
            return \"'\" + item.trim() + \"'\";
        });
        var target_vector = \"c(\" + target_array.join(', ') + \")\";

        echo(\"# Storytelling: Track specific bubbles\\n\");
        echo(\"p <- p + ggplot2::geom_label(\\n\");
        echo(\"  ggplot2::aes(label = \" + col + \"),\\n\");
        echo(\"  data = subset(plot_data, \" + col + \" %in% \" + target_vector + \"),\\n\");
        echo(\"  vjust = -1.5, size = 5, fontface = 'bold', show.legend = FALSE, alpha = 0.8\\n\");
        echo(\")\\n\\n\");
    }

    echo(\"p <- p + ggplot2::\" + theme + \"(base_size = \" + base_sz + \")\\n\");

    if (show_leg !== '1') {
        echo(\"p <- p + ggplot2::theme(legend.position = 'none')\\n\");
    }

    var labs_call = [];
    if (title) labs_call.push(\"title = '\" + title + \"'\");
    if (sub) labs_call.push(\"subtitle = '\" + sub + \"'\");
    if (xlab) labs_call.push(\"x = '\" + xlab + \"'\");
    if (ylab) labs_call.push(\"y = '\" + ylab + \"'\");
    if (caption) labs_call.push(\"caption = '\" + caption + \"'\");

    if (col !== 'NULL') {
        if (leg_title !== '') {
            labs_call.push(\"color = '\" + leg_title + \"'\");
        } else {
            // Extracción de etiquetas desde la base original (porque dplyr a veces las tira al filtrar)
            echo(\"\\n# Extraer etiqueta de variable para la leyenda\\n\");
            echo(\"col_lbl <- attr(\" + df + \"[['\" + col + \"']], 'variable.label')\\n\");
            echo(\"if(is.null(col_lbl)) col_lbl <- attr(\" + df + \"[['\" + col + \"']], '.rk.meta')[['label']]\\n\");
            echo(\"if(is.null(col_lbl)) col_lbl <- '\" + col + \"'\\n\");
            labs_call.push(\"color = col_lbl\");
        }
    }

    if (labs_call.length > 0) {
        echo(\"p <- p + ggplot2::labs(\" + labs_call.join(\", \") + \")\\n\");
    }

    echo(\"\\n# Animation settings\\n\");
    echo(\"p <- p + gganimate::transition_time(as.integer(as.character(\" + time + \"))) +\\n\");
    echo(\"  gganimate::ease_aes('linear')\\n\\n\");

    echo(\"cat('Rendering animation. This may take a minute...\\\\n')\\n\");
    echo(\"anim <- gganimate::animate(p, fps = \" + fps + \", duration = \" + dur + \", width = \" + w + \", height = \" + h + \", renderer = gganimate::gifski_renderer())\\n\");

    var safe_path = path.replace(/\\\\/g, '/');
    echo(\"gganimate::anim_save('\" + safe_path + \"', animation = anim)\\n\");
  ", sep = "\n")

  js_print_anim <- "
    var path = getValue('save_file');
    echo(\"rk.header('Animated Chart Generated')\\n\");
    var safe_path = path.replace(/\\\\/g, '/');
    echo(\"cat('Animation successfully saved to: \" + safe_path + \"\\\\n\\\\n')\\n\");
  "

  # =========================================================================================
  # 4. Final Skeleton Assembly
  # =========================================================================================
  rk.plugin.skeleton(
    about = package_about,
    path = ".",
    xml = list(dialog = dialog_gganim),
    js = list(require = c("ggplot2", "gganimate", "gifski", "dplyr"), calculate = js_calc_anim, printout = js_print_anim),
    components = list(comp_prep),
    pluginmap = list(
        name = "2. Animated Bubble Chart",
        hierarchy = list("Survey", "Graphs", "Animations")
    ),
    dependencies = dependencies_node,
    create = c("pmap", "xml", "js", "desc", "rkh"),
    overwrite = TRUE,
    load = TRUE
  )
})
